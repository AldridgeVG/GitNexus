import { SupportedLanguages, type NodeLabel } from 'gitnexus-shared';
import { defineLanguage } from '../language-provider.js';
import { pascalTypeConfig } from '../type-extractors/pascal.js';
import { pascalExportChecker } from '../export-detection.js';
import { resolvePascalImport } from '../import-resolvers/pascal.js';
import { extractPascalNamedBindings } from '../named-bindings/pascal.js';
import { PASCAL_QUERIES } from '../tree-sitter-queries.js';
import { createFieldExtractor } from '../field-extractors/generic.js';
import { pascalConfig } from '../field-extractors/configs/pascal.js';
import { createMethodExtractor } from '../method-extractors/generic.js';
import { pascalMethodConfig } from '../method-extractors/configs/pascal.js';
import { createCallExtractor } from '../call-extractors/generic.js';
import { createHeritageExtractor } from '../heritage-extractors/generic.js';
import type { SyntaxNode } from '../utils/ast-helpers.js';

function isPascalConstructorNode(node: SyntaxNode): boolean {
  // defProc has a 'header' field pointing to declProc, but interface declProc nodes
  // ARE the header themselves, so fall back to checking the node directly.
  const header = node.childForFieldName('header') ?? node;
  for (let i = 0; i < header.childCount; i++) {
    const child = header.child(i);
    if (child?.type === 'kConstructor' || child?.type === 'kDestructor') {
      return true;
    }
  }
  // declProc nodes (captured by @definition.function in the interface section)
  // do not have a header field; the keyword is a direct child.
  for (let i = 0; i < node.childCount; i++) {
    const child = node.child(i);
    if (child?.type === 'kConstructor' || child?.type === 'kDestructor') {
      return true;
    }
  }
  return false;
}

export const pascalProvider = defineLanguage({
  id: SupportedLanguages.Pascal,
  extensions: ['.pas', '.pp', '.lpr', '.dpr', '.dpk', '.inc'],
  treeSitterQueries: PASCAL_QUERIES,

  typeConfig: pascalTypeConfig,
  exportChecker: pascalExportChecker,
  importResolver: resolvePascalImport,
  namedBindingExtractor: extractPascalNamedBindings,

  mroStrategy: 'first-wins',

  fieldExtractor: createFieldExtractor(pascalConfig),
  methodExtractor: createMethodExtractor(pascalMethodConfig),
  callExtractor: createCallExtractor({ language: SupportedLanguages.Pascal }),
  heritageExtractor: createHeritageExtractor(SupportedLanguages.Pascal),

  labelOverride(node, defaultLabel): NodeLabel | null {
    if (defaultLabel === 'Function' && isPascalConstructorNode(node)) {
      return 'Constructor';
    }
    return defaultLabel;
  },
});
