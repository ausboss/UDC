import { spawn } from 'child_process';
import { TerminalSession, CommandExecutionResult, ActiveSession } from './types.js';
import { DEFAULT_COMMAND_TIMEOUT } from './config.js';

interface CompletedSession {
  pid: number;
  output: string;
  exitCode: number | null;
  startTime: Date;
  endTime: Date;
}

export class TerminalManager {
  private sessions: Map<number, TerminalSession> = new Map();
  private completedSessions: Map<number, CompletedSession> = new Map();
  
  async executeCommand(command: string, timeoutMs: number = DEFAULT_COMMAND_TIMEOUT, interactive: boolean = false): Promise<CommandExecutionResult> {
    // Use different spawn options based on interactive mode
    const spawnOptions = interactive ? 
      { shell: true, stdio: ['pipe', 'pipe', 'pipe'], detached: false } : 
      { shell: true };
    
    // Add terminal allocation for interactive sessions
    if (interactive && process.platform !== 'win32') {
      // On Unix systems, use 'script' to allocate a pseudo-terminal
      command = `script -qc "${command.replace(/"/g, '\\"')}" /dev/null`;
    } else if (interactive && process.platform === 'win32') {
      // On Windows, we can't easily allocate a pseudo-terminal, but we can try to make it work better
      // by using PowerShell and ConPTY if available
      command = `powershell -NoProfile -Command "${command.replace(/"/g, '\\"')}"`;
    }
    
    // Renamed 'process' to 'childProcess' to avoid collision with global 'process'
    const childProcess = spawn(command, [], spawnOptions);
    let output = '';
    
    // Ensure childProcess.pid is defined before proceeding
    if (!childProcess.pid) {
      throw new Error('Failed to get process ID');
    }
    
    const session: TerminalSession = {
      pid: childProcess.pid,
      process: childProcess,
      lastOutput: '',
      isBlocked: false,
      startTime: new Date(),
      interactive: interactive,
      inputBuffer: ''
    };
    
    this.sessions.set(childProcess.pid, session);

    return new Promise((resolve) => {
      childProcess.stdout.on('data', (data) => {
        const text = data.toString();
        output += text;
        session.lastOutput += text;
      });

      childProcess.stderr.on('data', (data) => {
        const text = data.toString();
        output += text;
        session.lastOutput += text;
      });

      // Different handling based on interactive mode
      if (!interactive) {
        // For non-interactive sessions, use timeout
        setTimeout(() => {
          session.isBlocked = true;
          resolve({
            pid: childProcess.pid!,
            output,
            isBlocked: true,
            interactive: false
          });
        }, timeoutMs);
      } else {
        // For interactive sessions, resolve immediately but keep the session open
        setTimeout(() => {
          resolve({
            pid: childProcess.pid!,
            output,
            isBlocked: false,
            interactive: true
          });
        }, 500); // Small delay to capture initial output
      }

      childProcess.on('exit', (code) => {
        if (childProcess.pid) {
          // Store completed session before removing active session
          this.completedSessions.set(childProcess.pid, {
            pid: childProcess.pid,
            output: output + session.lastOutput, // Combine all output
            exitCode: code,
            startTime: session.startTime,
            endTime: new Date()
          });
          
          // Keep only last 100 completed sessions
          if (this.completedSessions.size > 100) {
            const oldestKey = Array.from(this.completedSessions.keys())[0];
            this.completedSessions.delete(oldestKey);
          }
          
          this.sessions.delete(childProcess.pid);
        }
        
        if (!interactive) {
          resolve({
            pid: childProcess.pid!,
            output,
            isBlocked: false,
            interactive: false
          });
        }
      });
    });
  }

  // Send input to an interactive terminal session
  sendInput(pid: number, input: string): boolean {
    const session = this.sessions.get(pid);
    if (!session || !session.interactive || !session.process.stdin) {
      return false;
    }

    try {
      // Add a newline if not present
      if (!input.endsWith('\n')) {
        input += '\n';
      }
      
      session.process.stdin.write(input);
      return true;
    } catch (error) {
      console.error(`Failed to send input to process ${pid}:`, error);
      return false;
    }
  }

  getNewOutput(pid: number): string | null {
    // First check active sessions
    const session = this.sessions.get(pid);
    if (session) {
      const output = session.lastOutput;
      session.lastOutput = '';
      return output;
    }

    // Then check completed sessions
    const completedSession = this.completedSessions.get(pid);
    if (completedSession) {
      // Format completion message with exit code and runtime
      const runtime = (completedSession.endTime.getTime() - completedSession.startTime.getTime()) / 1000;
      return `Process completed with exit code ${completedSession.exitCode}\nRuntime: ${runtime}s\nFinal output:\n${completedSession.output}`;
    }

    return null;
  }

  forceTerminate(pid: number): boolean {
    const session = this.sessions.get(pid);
    if (!session) {
      return false;
    }

    try {
      session.process.kill('SIGINT');
      setTimeout(() => {
        if (this.sessions.has(pid)) {
          session.process.kill('SIGKILL');
        }
      }, 1000);
      return true;
    } catch (error) {
      console.error(`Failed to terminate process ${pid}:`, error);
      return false;
    }
  }

  listActiveSessions(): ActiveSession[] {
    const now = new Date();
    return Array.from(this.sessions.values()).map(session => ({
      pid: session.pid,
      isBlocked: session.isBlocked,
      runtime: now.getTime() - session.startTime.getTime(),
      interactive: session.interactive
    }));
  }

  listCompletedSessions(): CompletedSession[] {
    return Array.from(this.completedSessions.values());
  }
}

export const terminalManager = new TerminalManager();