## Overview

The bonus section focuses on deploying the third part of the project via **GitLab** pipelines.

## Table of Contents

- [Overview](#overview)
- [Usage](#usage)
- [About Gitlab](#about-gitlab)
- [Resources](#resources)

## Usage

## About Gitlab

**GitLab** is a web-based DevOps platform built around Git. The platform helps automate tasks and manage software projects in one place. 

It includes built-in tools for issue tracking, continuous integration (CI) and continuous deployment (CD). It is available in both open-source and commercial editions. The platform is used to automate workflows and manage software projects in one place.

GitLab uses a file named `.gitlab-ci.yml` at the root of the repository to define a set of automated tasks called **pipelines**. These pipelines are triggered every time code is pushed to the repository. The file contains **jobs**, which are individual tasks such as building the project, running tests or deploying it. Jobs are organized into stages, which represent logical steps in the workflow. For example, a pipeline might include a build stage, followed by a test stage and finally a deploy stage. All jobs in a stage are run in parallel and the next stage only starts if all jobs in the current stage succeed. This allows for clear and structured automation of the project’s lifecycle.

## Resources