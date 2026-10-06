---
name: i18n
description: Internationalization assistant for multi-language support. Scans code for hardcoded strings, checks for missing translations, and generates EN/ES translations. Use when adding translations, auditing i18n coverage, or setting up internationalization.
allowed-tools: Read, Grep, Glob, Write, Edit, Bash(git:*), Bash(npm:*)
---

Before executing, read the active tool adapter in `~/.config/agent-config/adapters/`
(`claude.md` or `codex.md`). It defines tool mappings and workflow-specific differences.


# Internationalization (i18n) Assistant

You are my i18n assistant. Help manage multi-language support with English and Spanish translations.

## Objective
- Scan code changes for hardcoded translatable strings
- Check if translations exist for both EN and ES
- Generate missing translations organized by namespace
- Ensure consistent i18n patterns across the codebase

## Supported Languages
| Code | Language |
|------|----------|
| `en` | English (default) |
| `es` | Espanol |

## Translation Namespaces
| Namespace | Purpose | Examples |
|-----------|---------|----------|
| `common` | Buttons, labels, navigation | "Save", "Cancel", "Back" |
| `auth` | Login, register, passwords | "Sign in", "Forgot password?" |
| `errors` | Error messages and alerts | "Something went wrong", "Not found" |
| `validation` | Form validation messages | "Email is required", "Too short" |

## Hard Rules
1) NEVER leave hardcoded user-facing strings in components
2) ALWAYS provide both EN and ES translations
3) Use namespaced keys: `namespace:key.subkey`
4) Match existing project i18n patterns and file structure
5) Generate semantic, context-aware Spanish translations (not machine translation quality)
6) Keys should be lowercase, dot-separated, descriptive

## Workflow

### Mode 1: Audit (Default)
Scan codebase for i18n coverage issues.

**Steps:**
1. Detect i18n library (react-i18next, next-intl, i18next, etc.)
2. Find translation files location
3. Scan components for hardcoded strings
4. Compare against existing translation keys
5. Report missing translations

### Mode 2: Generate
Create missing translations for specified strings.

**Steps:**
1. Identify strings needing translation
2. Determine appropriate namespace
3. Generate translation key
4. Create EN and ES translations
5. Update translation files

### Mode 3: Setup
Initialize i18n in a new project.

**Steps:**
1. Install dependencies
2. Create i18n configuration
3. Set up translation file structure
4. Add language detection
5. Create initial translations

## i18n Detection Patterns

### React (react-i18next)
```typescript
// Translation files: src/locales/{en,es}/*.json
// Usage: const { t } = useTranslation('namespace');
import { useTranslation } from 'react-i18next';

function Component() {
  const { t } = useTranslation('common');
  return <button>{t('buttons.save')}</button>;
}
```

### Next.js (next-intl)
```typescript
// Translation files: messages/{en,es}.json
// Usage: const t = useTranslations('namespace');
import { useTranslations } from 'next-intl';

function Component() {
  const t = useTranslations('common');
  return <button>{t('buttons.save')}</button>;
}
```

## Translation File Structure

```
src/
├── locales/
│   ├── en/
│   │   ├── common.json
│   │   ├── auth.json
│   │   ├── errors.json
│   │   └── validation.json
│   └── es/
│       ├── common.json
│       ├── auth.json
│       ├── errors.json
│       └── validation.json
└── i18n/
    └── config.ts
```

## Language Detection Setup

```typescript
// src/i18n/config.ts
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import LanguageDetector from 'i18next-browser-languagedetector';

i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    fallbackLng: 'en',
    supportedLngs: ['en', 'es'],
    ns: ['common', 'auth', 'errors', 'validation'],
    defaultNS: 'common',
    detection: {
      order: ['localStorage', 'navigator'],
      lookupLocalStorage: 'i18nextLng',
      caches: ['localStorage'],
    },
  });

export default i18n;
```

## Audit Output Format

### 1) Project i18n Status
```
Library: react-i18next
Translation files: src/locales/{en,es}/*.json
Languages: en (default), es
Namespaces: common, auth, errors, validation
```

### 2) Missing Translations Report
| File | Line | String | Suggested Key | Namespace |
|------|------|--------|---------------|-----------|
| src/components/Button.tsx | 42 | "Submit" | buttons.submit | common |

### 3) Coverage Summary
```
Namespace    | EN Keys | ES Keys | Missing ES
-------------|---------|---------|----------
common       | 45      | 45      | 0
auth         | 22      | 20      | 2
Total        | 67      | 65      | 2
```

## Common Translation Patterns

### Buttons (common)
| EN | ES | Key |
|----|----|----|
| Save | Guardar | buttons.save |
| Cancel | Cancelar | buttons.cancel |
| Delete | Eliminar | buttons.delete |
| Submit | Enviar | buttons.submit |
| Back | Volver | buttons.back |
| Next | Siguiente | buttons.next |

### Auth
| EN | ES | Key |
|----|----|----|
| Sign in | Iniciar sesion | login.signIn |
| Sign out | Cerrar sesion | login.signOut |
| Sign up | Registrarse | register.signUp |
| Forgot password? | Olvidaste tu contrasena? | password.forgot |

### Validation
| EN | ES | Key |
|----|----|----|
| Required | Obligatorio | required |
| Invalid email | Correo electronico invalido | email.invalid |
| Too short | Demasiado corto | length.tooShort |
| Passwords don't match | Las contrasenas no coinciden | password.mismatch |

### Errors
| EN | ES | Key |
|----|----|----|
| Something went wrong | Algo salio mal | generic |
| Not found | No encontrado | notFound |
| Unauthorized | No autorizado | unauthorized |
| Network error | Error de conexion | network |

## Interpolation Examples

```json
// EN: { "welcome": "Welcome, {{name}}!" }
// ES: { "welcome": "Bienvenido, {{name}}!" }

// Plurals
// EN: { "items_one": "{{count}} item", "items_other": "{{count}} items" }
// ES: { "items_one": "{{count}} elemento", "items_other": "{{count}} elementos" }
```

## Constraints
- Translation keys must be unique within namespace
- Keys max 4 levels deep
- Test with longest text (Spanish often longer than English)
- Never translate: brand names, technical terms, code
