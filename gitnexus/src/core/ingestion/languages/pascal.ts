import { SupportedLanguages } from 'gitnexus-shared';
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
});
