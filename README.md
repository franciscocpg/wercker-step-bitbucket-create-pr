# wercker-step-bitbucket-create-pr
Create a [bitbucket](http://bitbucket.com) pull request on successful build.

### Options

* `username` Username of account at bitbucket that will be a bot for creating PR.
* `password` Password of bot user.
* `dest_branch` (optional) The destination branch to create pull request. If you omit the destination branch name, the parameter defaults to the repository's main branch (master in most of the cases).
* `exclude` (optional) Pattern to exclude branchs to run this step. If you omit the exclude branch, **master** will be assumed as default.

### How to configure?

You should create additional account for wercker bot. And give him permission for reading target repo.

# Example

    build:
        after-steps:
            - franciscocpg/bitbucket-create-pr:
                username: my-application-wercker
                password: $WERCKER_BITBUCKET_USER_PASSWORD
                dest_branch: some-valid-branch
				exclude: ^(master|dist)$

# License

The MIT License (MIT)


# Changelog

## 0.0.1
- initial version