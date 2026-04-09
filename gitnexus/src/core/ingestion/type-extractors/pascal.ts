import type { LanguageTypeConfig, TypeBindingExtractor, ParameterExtractor } from './types.js';
import type { SyntaxNode } from '../utils/ast-helpers.js';
import { extractSimpleTypeName, extractVarName } from './shared.js';

// Pascal declaration node types - updated to match tree-sitter-pascal
const PASCAL_DECLARATION_NODE_TYPES: ReadonlySet<string> = new Set([
  'declVar', // variable declaration
  'declField', // field in class/record
  'declConst', // const declaration
  'declEnum', // enum declaration
  'declType', // type alias
]);

/** Pascal: var x: Type = ...; or field in class/record */
const extractPascalDeclaration: TypeBindingExtractor = (
  node: SyntaxNode,
  env: Map<string, string>,
): void => {
  // declField or declVar > type:(typeref) + name:(identifier)
  const typeNode = node.childForFieldName('type');
  if (!typeNode) return;
  const typeName = extractSimpleTypeName(typeNode);
  if (!typeName) return;

  // Direct name field for declField/declVar
  const nameNode = node.childForFieldName('name');
  if (nameNode) {
    const varName = extractVarName(nameNode);
    if (varName) env.set(varName, typeName);
    return;
  }

  // Fallback: check for identifier_list
  const namesNode = node.childForFieldName('names');
  if (namesNode?.type === 'identifier_list') {
    for (let i = 0; i < namesNode.namedChildCount; i++) {
      const ident = namesNode.namedChild(i);
      if (ident?.type === 'identifier') {
        const varName = extractVarName(ident);
        if (varName) env.set(varName, typeName);
      }
    }
  }
};

/** Pascal: parameter in procedure/function declaration (declArg) */
const extractPascalParameter: ParameterExtractor = (
  node: SyntaxNode,
  env: Map<string, string>,
): void => {
  // declArg > name:(identifier) + type:(typeref)
  const nameNode = node.childForFieldName('name');
  const typeNode = node.childForFieldName('type');
  if (!nameNode || !typeNode) return;

  const varName = extractVarName(nameNode);
  const typeName = extractSimpleTypeName(typeNode);
  if (varName && typeName) env.set(varName, typeName);
};

export const pascalTypeConfig: LanguageTypeConfig = {
  declarationNodeTypes: PASCAL_DECLARATION_NODE_TYPES,
  extractDeclaration: extractPascalDeclaration,
  extractParameter: extractPascalParameter,
};
