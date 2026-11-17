
## Visual verification

Anything a person will look at gets looked at before it is called done: web pages, app screens, terminal interfaces, charts, images, rendered documents.

- **Run it and look.** Open the real thing and read the screenshot yourself. Passing tests, type checks and layout assertions are not visual proof.
- **Capture before and after.** Take the before screenshot first, then the after, at the same size and state.
- **Cover what changes the picture.** For web work: light and dark, desktop and phone width, plus empty, loading and failure states when the change touches them.
- **Show the screenshots.** Put them in the pull request and give the full file paths in your report. A change to something visible with no screenshot is not finished.
- **Say what you did not see.** If a state could not be captured, name it and say why. Do not describe a screen you did not open.
- **Review the same way.** When reviewing someone else's visual change, open their screenshots or capture your own before approving.
