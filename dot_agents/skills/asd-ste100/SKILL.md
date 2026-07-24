---
name: asd-ste100
description: >
  Write or rewrite text in ASD-STE100 Simplified Technical English (STE): the
  approved-word dictionary discipline, controlled verb forms, sentence and
  paragraph limits, procedural vs descriptive rules, and safety-instruction
  structure. Use when the user asks for Simplified Technical English, STE,
  ASD-STE100, controlled language, or aerospace-style technical writing, or
  when authoring procedures, maintenance instructions, or safety warnings that
  must be unambiguous. Do NOT use for general documentation cleanup (use
  clean-docs), README structure (use write-readme), or ordinary prose style.
allowed-tools: Read, Grep, Glob, Edit, Write
user-invocable: true
metadata:
  title: Simplified Technical English (ASD-STE100)
  category: documentation
  order: 22
---

# Simplified Technical English (ASD-STE100)

Apply the ASD-STE100 specification (Issue 8) when writing or rewriting technical text. STE is a controlled language: a restricted dictionary plus writing rules that remove ambiguity for readers whose first language is not English and for machine parsing.

## When to Use

- The user invokes `/asd-ste100` or asks for STE, Simplified Technical English, or controlled language.
- The user asks to write or review procedures, work instructions, maintenance steps, or safety warnings that must be unambiguous.
- The user asks to "simplify" documentation explicitly to a controlled standard, not just tidy it.

## Core Principles

1. **One word, one meaning.** Each approved word has exactly one meaning and one part of speech. If a word is approved as a noun, do not use it as a verb.
2. **Approved words only.** General vocabulary comes from the STE dictionary (about 900 words). Everything else must qualify as a Technical Name or a Technical Verb.
3. **Short, direct, active.** Short sentences, active voice, one instruction per sentence.

## Vocabulary Rules

| Rule | Standard |
| ---- | -------- |
| Approved meaning only | Use a dictionary word only in its approved meaning. Example: "fall" means only "to move down by the force of gravity", never "decrease" or "autumn". |
| Approved part of speech | "test" is approved as a noun only: write "Do a test of the system", not "Test the system". |
| Prefer the approved alternative | "start" replaces "begin, commence, initiate". "do" replaces "carry out, perform". "before" replaces "prior to". |
| Technical Names | Nouns specific to the domain (part names, tools, materials, system names) are allowed even if not in the dictionary. Use them consistently and only as nouns. |
| Technical Verbs | Domain-specific actions (e.g. "to calibrate", "to drill") are allowed as verbs when no approved verb exists. |
| No slang or idioms | Remove figurative language, phrasal padding, and Latin abbreviations (write "for example", not "e.g."). |

## Grammar Rules

| Rule | Standard |
| ---- | -------- |
| Verb forms | Use only: infinitive, imperative, simple present, simple past, future with "will", and past participle as an adjective. |
| No -ing verb forms | Do not use gerunds or present participles ("Removing the cover..." becomes "When you remove the cover..."). An -ing form is allowed only inside a Technical Name. |
| Active voice | Use active voice in procedures always. In descriptive text, use passive only when the agent is unknown or unimportant. |
| Articles required | Do not drop articles or demonstratives: "Install the panel", not "Install panel". |
| Noun clusters | Maximum three nouns in a cluster. Break longer clusters with prepositions: "the fan of the cooling system", not "cooling system fan assembly housing". |
| Consistent naming | Use the same name for the same thing everywhere. No elegant variation. |

## Sentence and Paragraph Rules

| Rule | Standard |
| ---- | -------- |
| Procedural sentence length | Maximum 20 words. |
| Descriptive sentence length | Maximum 25 words. |
| Paragraph length | Maximum 6 sentences. One topic per paragraph. |
| One instruction per sentence | Split compound instructions. Only closely related actions may share a sentence. |
| Commands start instructions | Procedures begin with the imperative verb: "Remove the bolts", not "The bolts should be removed". |
| Vertical lists | Use a list when a sentence would hold more than three connected items. |

## Warnings, Cautions, and Notes

- **Warning**: risk of injury or death. **Caution**: risk of equipment damage. **Note**: helpful information only. Never put an instruction in a note.
- Put the warning or caution **before** the step it applies to.
- Start with a clear and simple command, then give the condition or reason: "WARNING: Do not touch the terminal. The terminal has a dangerous voltage."

## Rewriting Workflow

1. **Classify the text.** Procedural (instructions) or descriptive (explanations). The sentence limits and voice rules differ.
2. **Split and shorten.** Break sentences over the word limit. One instruction per sentence, one topic per paragraph.
3. **Convert the verbs.** Imperatives for steps, simple present for description, remove -ing forms and passives.
4. **Substitute vocabulary.** Replace unapproved general words with approved alternatives. Keep Technical Names and Technical Verbs, used consistently.
5. **Restructure safety text.** Move warnings and cautions before their steps, command first.
6. **Verify.** Recheck sentence lengths, noun clusters, articles, and that no word is used outside its approved meaning.

## Example

**Before:**

> Prior to commencing disassembly, ensuring the power has been disconnected is essential, as failure to do so may result in serious injury being sustained by maintenance personnel.

**After:**

> WARNING: Disconnect the power before you disassemble the unit. If you do not disconnect the power, injury can occur.

## Gotchas

- Do not apply STE to marketing copy, READMEs, or conversational docs unless asked. STE prose reads as terse and repetitive by design.
- Do not invent approved words. When unsure whether a general word is in the dictionary, prefer a simpler common alternative ("use", "make", "get", "do", "start", "stop").
- "May" is not approved for permission or possibility; use "can" for possibility.
- Keep required legal or certified text verbatim; STE rewrites must not alter regulatory wording.
