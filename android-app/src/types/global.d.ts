// Type declarations for React Native environment
// This file provides type definitions for global objects available in React Native

declare const console: {
  log: (...args: any[]) => void;
  error: (...args: any[]) => void;
  warn: (...args: any[]) => void;
  info: (...args: any[]) => void;
  debug: (...args: any[]) => void;
};

declare class FormData {
  append(name: string, value: any, fileName?: string): void;
  delete(name: string): void;
  get(name: string): any;
  getAll(name: string): any[];
  has(name: string): boolean;
  set(name: string, value: any, fileName?: string): void;
  entries(): IterableIterator<[string, any]>;
  keys(): IterableIterator<string>;
  values(): IterableIterator<any>;
  forEach(callback: (value: any, key: string, parent: FormData) => void): void;
}

declare const __DEV__: boolean;
