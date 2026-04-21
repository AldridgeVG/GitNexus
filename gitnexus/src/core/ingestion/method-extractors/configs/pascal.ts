// gitnexus/src/core/ingestion/method-extractors/configs/pascal.ts

import { SupportedLanguages } from 'gitnexus-shared';
import type {
  MethodExtractionConfig,
  ParameterInfo,
  MethodVisibility,
} from '../../method-types.js';
import type { SyntaxNode } from '../../utils/ast-helpers.js';
import { extractSimpleTypeName } from '../../type-extractors/shared.js';

const PASCAL_VIS = new Set<MethodVisibility>(['public', 'private', 'protected']);

function findPascalVisibility(node: SyntaxNode): MethodVisibility {
  const visKeywords: MethodVisibility[] = ['public', 'private', 'protected'];
  for (let i = 0; i < node.childCount; i++) {
    const child = node.child(i);
    if (child && visKeywords.includes(child.text as MethodVisibility)) {
      return child.text as MethodVisibility;
    }
  }
  // Check siblings in parent
  if (node.parent) {
    for (let i = 0; i < node.parent.childCount; i++) {
      const sibling = node.parent.child(i);
      if (sibling && visKeywords.includes(sibling.text as MethodVisibility)) {
        return sibling.text as MethodVisibility;
      }
    }
  }
  return 'public';
}

function extractPascalParameters(node: SyntaxNode): ParameterInfo[] {
  const params: ParameterInfo[] = [];

  // tree-sitter-pascal: defProc > header:(declProc) > declArgs
  const header = node.childForFieldName('header');
  if (!header) return params;

  const declArgs = header.children.find((c) => c.type === 'declArgs');
  if (!declArgs) return params;

  for (let i = 0; i < declArgs.namedChildCount; i++) {
    const param = declArgs.namedChild(i);
    if (!param || param.type !== 'declArg') continue;

    // declArg children: identifier, ':', type
    const nameNode = param.child(0);
    const typeNode = param.child(2);

    if (nameNode && nameNode.type === 'identifier') {
      params.push({
        name: nameNode.text,
        type: typeNode ? (extractSimpleTypeName(typeNode) ?? typeNode.text?.trim()) : null,
        isOptional: false, // Pascal doesn't have optional params in the same way
        isVariadic: false,
      });
    }
  }

  return params;
}

function extractPascalReturnType(node: SyntaxNode): string | undefined {
  // tree-sitter-pascal: defProc > header:(declProc) — return type sits after ':' token
  const header = node.childForFieldName('header');
  if (!header) return undefined;

  let foundColon = false;
  for (let i = 0; i < header.childCount; i++) {
    const child = header.child(i);
    if (child?.type === ':') {
      foundColon = true;
      continue;
    }
    if (foundColon && child && child.isNamed) {
      return extractSimpleTypeName(child) ?? child.text?.trim();
    }
  }
  return undefined;
}

export const pascalMethodConfig: MethodExtractionConfig = {
  language: SupportedLanguages.Pascal,
  // Updated to match tree-sitter-pascal node types
  typeDeclarationNodes: ['declClass', 'declIntf', 'declHelper'],
  methodNodeTypes: [
    'defProc', // procedure/function definition
    'declProcFwd', // forward declaration
  ],
  bodyNodeTypes: ['declSection', '_declClass'],

  extractName(node) {
    // defProc > header:(declProc) > name:(identifier)
    const header = node.childForFieldName('header');
    const nameNode = header?.childForFieldName('name') ?? node.childForFieldName('name');
    if (!nameNode) return undefined;
    // tree-sitter-pascal's declProc name field may include the class prefix
    // (e.g. "TClass.Method"). Strip it so names match query-capture IDs.
    const raw = nameNode.text;
    return raw.includes('.') ? raw.slice(raw.lastIndexOf('.') + 1) : raw;
  },

  extractReturnType(node) {
    return extractPascalReturnType(node);
  },

  extractParameters: extractPascalParameters,

  extractVisibility(node) {
    return findPascalVisibility(node);
  },

  isStatic(_node) {
    // Pascal class methods are marked with 'class' keyword
    // Check for class keyword in proc attributes
    return false;
  },

  isAbstract(node, _ownerNode) {
    // Check for abstract/virtual modifiers in procAttribute
    const header = node.childForFieldName('header') ?? node;
    for (let i = 0; i < header.childCount; i++) {
      const child = header.child(i);
      if (
        child &&
        (child.text === 'abstract' || child.text === 'virtual' || child.text === 'dynamic')
      ) {
        return true;
      }
    }
    return false;
  },

  isFinal(node) {
    // Check for override without virtual/dynamic = final
    const header = node.childForFieldName('header') ?? node;
    let hasOverride = false;
    let hasVirtual = false;
    for (let i = 0; i < header.childCount; i++) {
      const child = header.child(i);
      if (child) {
        if (child.text === 'override') hasOverride = true;
        if (child.text === 'virtual' || child.text === 'dynamic') hasVirtual = true;
      }
    }
    return hasOverride && !hasVirtual;
  },

  extractFunctionName(node) {
    const header = node.childForFieldName('header');
    const nameNode = header?.childForFieldName('name') ?? node.childForFieldName('name');
    if (nameNode) {
      let label: 'Function' | 'Constructor' = 'Function';
      if (header) {
        for (let i = 0; i < header.childCount; i++) {
          const child = header.child(i);
          if (child?.type === 'kConstructor' || child?.type === 'kDestructor') {
            label = 'Constructor';
            break;
          }
        }
      }
      // Align with extractName: strip class prefix so IDs match definition phase.
      const raw = nameNode.text;
      const funcName = raw.includes('.') ? raw.slice(raw.lastIndexOf('.') + 1) : raw;
      return { funcName, label };
    }
    return undefined;
  },
};
