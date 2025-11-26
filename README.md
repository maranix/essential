# Essential Workspace

This workspace contains a collection of reusable building blocks designed to improve development efficiency and overall code quality in Dart and Flutter projects.

## Packages

| Package | Description | Version | Pub.dev |
|---|---|---|---|
| [essential_dart](./packages/essential_dart) | Reusable building blocks, patterns, and services for Dart. | 1.0.0+1 | [![Pub](https://img.shields.io/pub/v/essential_dart)](https://pub.dev/packages/essential_dart) |
| [essential_flutter](./packages/essential_flutter) | Flutter widgets, components, and services building on essential_dart. | 1.0.0+1 | [![Pub](https://img.shields.io/pub/v/essential_flutter)](https://pub.dev/packages/essential_flutter) |

## Overview

It is available in two variants—one for pure Dart environments and one for Flutter applications.

### essential_dart
The Dart version offers language-level utilities such as helper classes, patterns, services, and common abstractions that streamline application logic. This includes features like sealed classes for representing UI or operation states (e.g., loading, loaded, failure) and other reusable code snippets aimed at reducing boilerplate and promoting consistency.

### essential_flutter
The Flutter version builds on top of the Dart package by re-exporting all Dart utilities while adding Flutter-specific widgets, components, and services. This unified approach allows developers to access both Dart and Flutter utilities through a single import, accelerating UI development and encouraging clean architectural practices through well-structured reusable widgets and ready-to-use patterns.

Together, these packages provide a unified toolkit that enhances developer experience, speeds up development velocity, and enforces maintainable, scalable coding practices across both Dart and Flutter projects.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
