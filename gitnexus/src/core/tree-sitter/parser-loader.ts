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

// ===== 加载 Pascal 解析器 =====
let Pascal: any = null;
try {
  Pascal = _require('@fsdev/tree-sitter-pascal');
} catch (e: any) {
  // 调试：打印加载错误（仅在 DEBUG 环境变量时输出）
  if (process.env.DEBUG) {
    console.error('[gitnexus-debug] Failed to load @fsdev/tree-sitter-pascal:', e.message);
    console.error('[gitnexus-debug] import.meta.url:', import.meta.url);
    console.error('[gitnexus-debug] __dirname:', __dirname);
  }
}

// ===== 加载可选 Swift 解析器 =====
let Swift: any = null;
try {
  Swift = _require('tree-sitter-swift');
} catch {}

// ===== 加载可选 Dart 解析器 =====
let Dart: any = null;
try {
  Dart = _require('tree-sitter-dart');
} catch {}

// ===== 加载可选 Kotlin 解析器 =====
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
