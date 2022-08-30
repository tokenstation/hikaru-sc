# How to contribute to Hikaru

## Filing an issue

If you find a bug or want to improve existing code base, please [open an issue](https://github.com/tokenstation/hikaru-sc/issues). Pull requests without an issue will be reviewed but we recommend opening issue first.

## Filing a bug

If you find a bug and want us to know about it - [open an issue](https://github.com/tokenstation/hikaru-sc/issues) and describe what kind of a bug you experienced.

Minimal info required:
- General bug description (for example: "I've tried to swap tokens, but as a result provided tokens to another DeFi...")
- Transaction Id or similar info using which we can determine transaction id
- If you found a bug programmatically - we would appreciate information on how to reproduce error

## Filing an improvement suggestion

If you want to make an improvement suggestion we will need following information:
- Introduction: what would you like to improve
- Why: why this improvement should be implemented (for example: Improvement "X" will be better for users because "Y", ...)
- How: if you have any suggestions on how this improvement should be done (for example: To achive "X" we must make "Y", ...)

## Filing code-related improvement suggestion

This is done like previously mentioned, but you must be more specific about what changes you want to implement - maybe it's related to specific file or project in general.

# Installation and testing

This project uses [```yarn```](https://yarnpkg.com/) as package manager.

To install [```yarn```](https://yarnpkg.com/):
```bash
npm install -g yarn
```

Some routines will require installed TypeScript (for example to generate typechain bindings):
```bash
npm install -g ts-node
```

## Installation

Install required packages locally:
```bash
yarn
```

## Testing

Run default tests:
```bash
yarn hh-test
```

Run tests with gas-report:
```bash
yarn hh-gas-report
```

Run tests with coverage report:
```bash
yarn hh-coverage
```
