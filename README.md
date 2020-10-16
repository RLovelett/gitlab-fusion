# gitlab-fusion

![Continuous Integration (CI)](https://github.com/RLovelett/gitlab-fusion/workflows/Continuous%20Integration%20(CI)/badge.svg)

`gitlab-fusion` is a [custom executor](https://docs.gitlab.com/13.4/runner/executors/custom.html)
for GitLab Runner. This custom executor allows for the creation of a clean build
environment from a known base state for every job executed by CI.

This custom executor integrates well with
[Console on Mac](https://support.apple.com/guide/console/log-messages-cnsl1012/mac)
and the rest of the Swift ecosystem in an effort to provide easy development,
debugging and integration on macOS.

> ***NOTE***: All guests MUST have the VMware Fusion guest additions installed
> and expose an SSH server.

## Dependencies

macOS 10.13.x (High Sierra) or later is required as a host operating system.
VMware Fusion host operating system support matrix can be
found in [KB: 2088571 - Supported host operating systems for VMware Fusion and VMware Fusion Pro](https://kb.vmware.com/s/article/2088571).
Fusion 11.5.x is known to work with this custom executor this is why macOS
10.13.x (High Sierra) is the oldest supported host operating system.

Additionally, `gitlab-fusion` has a runtime dependency on
[libssh](https://www.libssh.org). There are multiple ways to install libssh but
the recommended way is through [Homebrew](https://brew.sh). It is beyond the
scope of this document to explain how to install libssh. Just ensure it is
available on your runpath.

## Build

* Debug: `swift build`
* Release: `swift build -c release`

## Command Line Usage

```
gitlab-fusion <subcommand> [OPTIONS]
```

It is a goal that the tool itself has _adequate_ documentation in the help
available at the point of usage. A good place to start is to simply run
`gitlab-fusion --help` and see if the flag, option or argument is documented
there.

The `gitlab-fusion` tool provides 4 subcommands `config`, `prepare`, `run` and
`cleanup`. These subcommands are designed to be called by the corresponding
custom executor [stages](https://docs.gitlab.com/13.4/runner/executors/custom.html#stages)
of the same names.

Each subcommand accepts the configuration of the location of the VMware Fusion
application and where the managed linked clones will be stored.

* `--vmware-fusion`: Fully qualified path to the VMware Fusion application.
(default: `/Applications/VMware Fusion.app`)

* `--vm-images-path`: Fully qualified path to directory where cloned images are
stored. (default: `$HOME/Virtual Machines.localized`)

### Config

This subcommand should be called by the
[config_exec](https://docs.gitlab.com/runner/executors/custom.html#config)
stage.

This subcommand generates a properly formatted JSON string and serializes it to
STDOUT. The keys of the JSON string are determined by the GitLab Runner custom
executor API. While the values of the JSON are determined by the options
provided by this step.

See `gitlab-runner config --help` for more detail on the options.

### Prepare

This subcommand should be called by the
[prepare_exec](https://docs.gitlab.com/runner/executors/custom.html#prepare)
stage.

This subcommand is responsible for creating the clean and isolated build
environment that the job will use.

To achieve the goal of a clean and isolated build environment this command must
be provided the path to a base guest virtual machine. The `prepare` subcommand
will then create a snapshot on base guest (if necessary) and then make a linked
clone of the snapshot (if necessary).

The linked clone will also have a snapshot created. This snapshots will
represent the clean base state of any job. Finally, the subcommand will restore
from the snapshot and start the cloned guest.

Once the guest is started. The subcommand will wait for the guest to boot and
provide its IP address via the VMware Guest Additions. Before signaling that
the guest is working the prepare subcommand will also ensure that the SSH
server is responding and that the supplied credentials work.

See `gitlab-runner prepare --help` for more detail on the options and arguments.

### Run

This subcommand should be called by the
[run_exec](https://docs.gitlab.com/runner/executors/custom.html#run) stage.

The run subcommand is responsible for executing the scripts provided by GitLab
Runner in the prepared guest virtual machine.

Provided that the `prepare` stage has already been performed this command is
safe to call multiple times.

See `gitlab-runner run --help` for more detail on the options and arguments.

### Cleanup

This subcommand should be called by the
[cleanup_exec](https://docs.gitlab.com/runner/executors/custom.html#cleanup)
stage.

The cleanup subcommand is responsible for stopping the cloned guest virtual
machine.

See `gitlab-runner cleanup --help` for more detail on the options and arguments.

## Example Integration with GitLab Runner

It is well beyond the scope of this project to explain how to install and configure
a GitLab Runner. There are existing guides on how to do that. Please follow one
of them.

* [Install GitLab Runner](https://docs.gitlab.com/runner/install/)
* [Install GitLab Runner](https://docs.gitlab.com/runner/#install-gitlab-runner)
* [Registering runner](https://docs.gitlab.com/runner/register/index.html)
* [The Custom executor](https://docs.gitlab.com/runner/executors/custom.html)

At a high level, to use this executor one must install GitLab Runner. Then
register a custom executor with GitLab Runner. Then finally configure the custom
executor to use `gitlab-fusion`.

That final step is where `gitlab-runner` needs to be told where the base VMware
guest is located and be provided appropriate SSH credentials for that guest.

The excerpt below assumes that the `gitlab-runner` executable is located at
`/Users/buildbot/gitlab-fusion/.build/release/gitlab-fusion`. Additionally that
the base guest virtual machine is located at
`/Users/buildbot/base-macOS-10.15.7-19H2-xcode-12.0.0.vmwarevm/base-macOS-10.15.7-19H2-xcode-12.0.0.vmx`.
Your path is likely different and should be updated accordingly.

All of the arguments available to the `config_args`, `prepare_args`, `run_args`
and `cleanup_args` should be located in the respective help of each subcommand.

```toml
...

[[runners]]
  ...
  [runners.custom]
    config_exec = "/Users/buildbot/gitlab-fusion/.build/release/gitlab-fusion"
    config_args = [
      "config"
    ]

    prepare_exec = "/Users/buildbot/gitlab-fusion/.build/release/gitlab-fusion"
    prepare_args = [
      "prepare",
      "--ssh-username", "buildbot",
      "--ssh-identity-file", "/Users/buildbot/Library/Application Support/me.lovelett.gitlab-fusion/id_ed25519",
      "/Users/buildbot/base-macOS-10.15.7-19H2-xcode-12.0.0.vmwarevm/base-macOS-10.15.7-19H2-xcode-12.0.0.vmx"
    ]

    run_exec = "/Users/buildbot/gitlab-fusion/.build/release/gitlab-fusion"
    run_args = [
      "run",
      "--ssh-username", "buildbot",
      "--ssh-identity-file", "/Users/buildbot/Library/Application Support/me.lovelett.gitlab-fusion/id_ed25519",
      "/Users/buildbot/base-macOS-10.15.7-19H2-xcode-12.0.0.vmwarevm/base-macOS-10.15.7-19H2-xcode-12.0.0.vmx"
    ]

    cleanup_exec = "/Users/buildbot/gitlab-fusion/.build/release/gitlab-fusion"
    cleanup_args = [
      "cleanup",
      "/Users/buildbot/base-macOS-10.15.7-19H2-xcode-12.0.0.vmwarevm/base-macOS-10.15.7-19H2-xcode-12.0.0.vmx"
    ]
```
