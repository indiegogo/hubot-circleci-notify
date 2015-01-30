Receive notifications when your CircleCI build finishes.

## Installation

Run `npm install --save hubot-circleci-notify`

Add __hubot-circleci-notify__ to your `external-scripts.json`

```javascript
["hubot-circleci-notify"]
```

You'll need to set up a webhook from Circle CI to your hubot at the HTTP endpoint `/hubot/circleci`.

## Commands

- `hubot ci[rcle] alert <repo> <branch>` - Receive alerts when a build finishes for the given repo/branch.
- `hubot ci[rcle] rm alert <repo> <branch>` - Stop receiving alerts when a build finishes on the given repo/branch.
- `hubot ci[rcle] build alert [build number]` - Receive an alert when this build finishes.

Note: `<repo>` is case-insensitive, and does _not_ include the repository owner, just the name.
