# Grahvani Project & Development Rules

This document establishes the official development workflow, implementation rules, and documentation standards for the **Grahvani** project. All developers, AI agents, and contributors must strictly adhere to these rules to maintain codebase stability, ensure backward compatibility, and keep feature tracking accurate throughout the software development lifecycle.

---

## 1. Development Workflow

* **Backlog Verification**: Before starting any work, review the feature tracking Markdown file ([Master Feature Tracking.md](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/FeatTracking/Master%20Feature%20Tracking.md)) that contains the current feature list and statuses. If any features are marked incorrectly, use that file as the source of truth and update the implementation plan accordingly.
* **Priority Order**: Always select the **next highest-priority pending ticket** for implementation.
* **Non-Breaking Guarantee**: Only work on tickets that can be implemented **without breaking existing functionality**.
* **Backward Compatibility**: Preserve backward compatibility and ensure all currently working features continue to function after each change.
* **Dependency Resolution**: If a ticket depends on unfinished work, clearly document the dependency and move to the next eligible ticket.

---

## 2. Implementation Rules

* **Focused Scope**: Keep changes focused on the current ticket.
* **Minimal Refactoring**: Avoid unrelated refactoring unless it is required to complete the task safely.
* **Architectural Alignment**: Follow the existing project architecture, coding standards, and conventions.
* **Verification Before Completion**: Verify that the project builds successfully and that existing functionality remains intact before considering a ticket complete.

---

## 3. Documentation Rules

* **Documentation Assessment**: At the end of every completed task, determine whether the changes are significant enough to warrant documentation.
* **README & Core Updates**: If they are, update `README.md` with the new feature, behavior, setup changes, or any other relevant information.
* **Feature Tracking Maintenance**: Keep the feature tracking Markdown file up to date by marking completed features, updating statuses, and adding implementation notes where appropriate.
* **Zero Documentation Drift**: Never leave the documentation out of sync with the current state of the project.
