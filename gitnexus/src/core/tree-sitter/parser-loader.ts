import Parser from 'tree-sitter';
import JavaScript from 'tree-sitter-javascript';
import TypeScript from 'tree-sitter-typescript';
import Python from 'tree-sitter-python';
import Java from 'tree-sitter-java';
import C from 'tree-sitter-c';
import CPP from 'tree-sitter-cpp';
import CSharp from 'tree-sitter-c-sharp';
import Go from 'tree-sitter-go';
import Rust from 'tree-sitter-rust';
import PHP from 'tree-sitter-php';
import Ruby from 'tree-sitter-ruby';

import { createRequire } from 'node:module';
import { SupportedLanguages } from 'gitnexus-shared';
import { fileURLToPath } from 'url';
import path from 'path';

// tree-sitter-swift and tree-sitter-dart are optionalDependencies — may not be installed
const _require = createRequire(import.meta.url);
const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ===== 加载本地 Pascal 解析器 =====//
let Pascal: any = null;
function loadPascalParser(): any {
  // 尝试多个可能的路径
  const possiblePaths = [
    // 1. 标准 npm 包路径（如果已发布）
    'tree-sitter-pascal',
    // 2. 开发环境：相对于 src/core/tree-sitter/
    path.resolve(__dirname, '../../vendor/tree-sitter-pascal'),
    // 3. 打包后：相对于 dist/core/tree-sitter/
    path.resolve(__dirname, '../vendor/tree-sitter-pascal'),
    // 4. 相对于工作目录
    path.resolve(process.cwd(), 'vendor/tree-sitter-pascal'),
  ];
  for (const tryPath of possiblePaths) {
    try {
      const parser = _require(tryPath);
      // 验证 ABI 兼容性：尝试创建一个临时 parser 并 setLanguage
      const Parser = _require('tree-sitter');
      const testParser = new Parser();
      testParser.setLanguage(parser);
      return parser;
    } catch (err: any) {
      // ABI 不兼容或其他错误，跳过
      continue;
    }
  }
  return null;
}
Pascal = loadPascalParser();

// ===== 加载可选 Swift 解析器 =====//
let Swift: any = null;
try {
  Swift = _require('tree-sitter-swift');
} catch {}

// ===== 加载可选 Dart 解析器 =====//
let Dart: any = null;
try {
  Dart = _require('tree-sitter-dart');
} catch {}

// ===== 加载可选 Kotlin 解析器 =====//
let Kotlin: any = null;
try {
  Kotlin = _require('tree-sitter-kotlin');
} catch {}

let parser: Parser | null = null;

const languageMap: Record<string, any> = {
  [SupportedLanguages.JavaScript]: JavaScript,
  [SupportedLanguages.TypeScript]: TypeScript.typescript,
  [`${SupportedLanguages.TypeScript}:tsx`]: TypeScript.tsx,
  [SupportedLanguages.Python]: Python,
  [SupportedLanguages.Java]: Java,
  [SupportedLanguages.C]: C,
  [SupportedLanguages.CPlusPlus]: CPP,
  [SupportedLanguages.CSharp]: CSharp,
  [SupportedLanguages.Go]: Go,
  [SupportedLanguages.Rust]: Rust,
  [SupportedLanguages.PHP]: PHP.php_only,
  [SupportedLanguages.Ruby]: Ruby,
  [SupportedLanguages.Vue]: TypeScript.typescript,
  ...(Dart ? { [SupportedLanguages.Dart]: Dart } : {}),
  ...(Swift ? { [SupportedLanguages.Swift]: Swift } : {}),
  ...(Kotlin ? { [SupportedLanguages.Kotlin]: Kotlin } : {}),
  ...(Pascal ? { [SupportedLanguages.Pascal]: Pascal } : {}),
};

export const isLanguageAvailable = (language: SupportedLanguages): boolean =>
  language in languageMap;

export const loadParser = async (): Promise<Parser> => {
  if (parser) return parser;
  parser = new Parser();
  return parser;
};

export const loadLanguage = async (
  language: SupportedLanguages,
  filePath?: string,
): Promise<void> => {
  if (!parser) await loadParser();
  const key =
    language === SupportedLanguages.TypeScript && filePath?.endsWith('.tsx')
      ? `${language}:tsx`
      : language;

  const lang = languageMap[key];
  if (!lang) {
    throw new Error(`Unsupported language: ${language}`);
  }
  parser!.setLanguage(lang);
};
