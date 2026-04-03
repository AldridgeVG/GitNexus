import type { SyntaxNode } from '../utils/ast-helpers.js';
import type { NamedBinding } from './types.js';

export function extractPascalNamedBindings(_importNode: SyntaxNode): NamedBinding[] | undefined {
  // Pascal uses clause imports entire units (wildcard imports), not named bindings.
  // Example: uses SysUtils, Classes, MyUnit;
  // No named extraction needed - return undefined to signal no named imports.
  return undefined;
}
