import fs from 'fs';
import path from 'path';
import type { ImportResolverFn, ImportResult } from './types.js';

export const resolvePascalImport: ImportResolverFn = (
  importName: string,
  currentFile: string,
  _resolveCtx,
): ImportResult => {
  const extensions = ['.pas', '.pp', '.lpr', '.dpr', '.dpk', '.inc'];
  const repoRoot = path.resolve(path.dirname(currentFile), '..'); // Simplified root detection
  const dirs = [
    repoRoot,
    path.join(repoRoot, 'src'),
    path.join(repoRoot, 'units'),
    path.dirname(currentFile),
  ];

  for (const dir of dirs) {
    for (const ext of extensions) {
      const files = [
        path.join(dir, importName + ext),
        path.join(dir, importName.toLowerCase() + ext),
      ];
      for (const file of files) {
        if (fs.existsSync(file)) {
          return { kind: 'files', files: [file] };
        }
      }
    }
  }

  return null;
};
