# Shared website design approach

## Start with the person and their next action

Identify the main visitor intents before drawing the page. A business site may
need a clear route for new customers and a shorter route for existing customers.
Put those choices near the top using direct labels. For a gym, that could be
“New here? Book a free trial” and “Already a member? Schedule and account.”
Keep one visually primary action in view. Repeating the same filled button in
the header, hero, cards and sticky bar creates noise. On phones, use one
persistent action when useful and avoid duplicating it in adjacent sections.
Class or product cards can use quieter selection actions.

Keep the same action in the same flow. All entry points should use one reusable
form or booking component and preserve selected class, product or program.
Prefer a short form on the current page when it is sufficient. Introduce steps
only when the task needs them. Clearly distinguish requested, confirmed and
preview states.

## A page that works while walking and scrolling

Design the narrow viewport first. Use a natural downward reading order, short
paragraphs, meaningful headings and the practical facts needed to act. Avoid
horizontal carousels for essential information. A timetable can become an agenda
on phones. Keep supplementary content below the immediate decisions.

Use visible desktop navigation when it fits. Use a labeled hamburger on smaller
screens, with logical groups and direct links to the essential pages. The menu
needs an expanded state, keyboard access, Escape behavior and visible focus.
Existing customers should not have to traverse a new-customer sales funnel.

Use descriptive links: “Class schedule,” “Member portal,” “Entrance directions,”
or “First class: what to wear and bring.” Avoid repeated “Learn more,” “Click
here,” ambiguous icon-only actions or unexplained external destinations. Keep
important information available as linked pages as well as homepage sections.

## Typography, surfaces and motion

Choose and document a real font family. Self-host it when licensing permits and
include its license, fallbacks and a sensible loading strategy. Keep a small type
scale and restrained weights. Body copy should be comfortably readable on a
phone; do not shrink essential information to make a layout fit. Manrope is a
useful starting point when no brand typeface exists, not a required brand font.

Define named color, spacing, type, radius and focus tokens once. Use solid,
readable surfaces behind text. Avoid washed-out photographs, decorative gradients,
excessive cards and glowing buttons that compete with the action. Each brand
still needs an intentional identity; a shared method is not a universal palette.

Use a little motion to clarify arrival or a user's action. Keep content readable
without waiting for animation. Avoid staggered reveals on every section,
autoplaying distractions and repeated looping cues. Honor reduced-motion
preferences, including smooth scrolling and dialog transitions.

## Accessible by construction

Use semantic HTML, a meaningful heading order, landmarks, descriptive image text
and explicit form labels. Keep native controls where they solve the interaction.
In a React project, shadcn/ui can provide consistent components when useful;
verify the resulting labels, focus and keyboard behavior rather than assuming
the library guarantees accessibility.

Check text contrast against the actual surface, visible focus, comfortable touch
targets, keyboard navigation, dialog focus/return, validation errors and menu
closure. Test reflow and zoom, not only a desktop screenshot. Don't claim WCAG
conformance from a handful of checks. Fix demonstrated barriers and name what
remains unverified.

## A reusable implementation, not a framework migration

For a new content-driven site, Astro with static HTML is a preferred starting
point; add React islands and shadcn/ui where interaction merits them. Preserve
the existing stack for a focused redesign unless the user requests a migration
or there is a concrete architectural reason to propose one. Reuse navigation,
forms, page shells and design tokens instead of copying variants between pages.

Keep business facts in one maintained source. Generate prices, schedule, contact
details and eligibility consistently across visible HTML, metadata, schema and
agent-readable files. Never invent policies, capacity, directions or proof.
Record unresolved business details for the owner to confirm.

## Humans and agents use the same facts

Render important content and links in initial HTML. Give distinct pages their
own title, description and canonical. Use valid structured data that matches the
page. Provide concise llms.txt guidance and discoverable Markdown when useful,
generated from the same content rather than maintained as stale copies. Treat
these files as an additional interface, not a guarantee of search visibility.

Forms need explicit labels and unambiguous results. Tracking should measure
real accepted leads, confirmations and downstream outcomes, not label button
clicks as sales. Keep personal form details out of ordinary analytics events.

## Verification before calling it finished

Check representative phone, tablet and laptop widths, including a narrow phone.
Look for horizontal overflow and controls obscured by sticky bars. Exercise the
primary flow, existing-customer route, internal/deep links, keyboard focus and
reduced motion. Use focused automated checks for meaningful behavior and share
screenshots from the actual implementation. Run the project's normal checks.
Keep preview-only behavior explicit, and deploy privately when review access is
intended. A private repository alone does not restrict a hosted website.
