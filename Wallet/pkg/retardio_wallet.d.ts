/* tslint:disable */
/* eslint-disable */

export class Wallet {
  free(): void;
  [Symbol.dispose](): void;
  address(): string;
  mnemonic(): string;
  static hashMessage(message: string): string;
  signMessage(message_hash: Uint8Array): string;
  static fromMnemonic(phrase: string, passphrase?: string | null): Wallet;
  publicKey(): string;
  privateKey(): string;
  static fromPrivateKey(hex: string): Wallet;
  verifySignature(message_hash: Uint8Array, signature_hex: string): boolean;
  constructor(passphrase?: string | null);
}

export type InitInput = RequestInfo | URL | Response | BufferSource | WebAssembly.Module;

export interface InitOutput {
  readonly memory: WebAssembly.Memory;
  readonly __wbg_wallet_free: (a: number, b: number) => void;
  readonly wallet_address: (a: number) => [number, number];
  readonly wallet_fromMnemonic: (a: number, b: number, c: number, d: number) => [number, number, number];
  readonly wallet_fromPrivateKey: (a: number, b: number) => [number, number, number];
  readonly wallet_hashMessage: (a: number, b: number) => [number, number];
  readonly wallet_mnemonic: (a: number) => [number, number];
  readonly wallet_new: (a: number, b: number) => number;
  readonly wallet_privateKey: (a: number) => [number, number];
  readonly wallet_publicKey: (a: number) => [number, number];
  readonly wallet_signMessage: (a: number, b: number, c: number) => [number, number, number, number];
  readonly wallet_verifySignature: (a: number, b: number, c: number, d: number, e: number) => number;
  readonly __wbindgen_exn_store: (a: number) => void;
  readonly __externref_table_alloc: () => number;
  readonly __wbindgen_externrefs: WebAssembly.Table;
  readonly __wbindgen_free: (a: number, b: number, c: number) => void;
  readonly __wbindgen_malloc: (a: number, b: number) => number;
  readonly __wbindgen_realloc: (a: number, b: number, c: number, d: number) => number;
  readonly __externref_table_dealloc: (a: number) => void;
  readonly __wbindgen_start: () => void;
}

export type SyncInitInput = BufferSource | WebAssembly.Module;

/**
* Instantiates the given `module`, which can either be bytes or
* a precompiled `WebAssembly.Module`.
*
* @param {{ module: SyncInitInput }} module - Passing `SyncInitInput` directly is deprecated.
*
* @returns {InitOutput}
*/
export function initSync(module: { module: SyncInitInput } | SyncInitInput): InitOutput;

/**
* If `module_or_path` is {RequestInfo} or {URL}, makes a request and
* for everything else, calls `WebAssembly.instantiate` directly.
*
* @param {{ module_or_path: InitInput | Promise<InitInput> }} module_or_path - Passing `InitInput` directly is deprecated.
*
* @returns {Promise<InitOutput>}
*/
export default function __wbg_init (module_or_path?: { module_or_path: InitInput | Promise<InitInput> } | InitInput | Promise<InitInput>): Promise<InitOutput>;
