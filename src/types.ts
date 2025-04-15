import { ChildProcess } from 'child_process';

export interface ProcessInfo {
  pid: number;
  command: string;
  cpu: string;
  memory: string;
}

export interface TerminalSession {
  pid: number;
  process: ChildProcess;
  lastOutput: string;
  isBlocked: boolean;
  startTime: Date;
  interactive?: boolean;
  inputBuffer?: string;
}

export interface CommandExecutionResult {
  pid: number;
  output: string;
  isBlocked: boolean;
  interactive?: boolean;
}

export interface ActiveSession {
  pid: number;
  isBlocked: boolean;
  runtime: number;
  interactive?: boolean;
}

export interface CompletedSession {
  pid: number;
  output: string;
  exitCode: number | null;
  startTime: Date;
  endTime: Date;
}