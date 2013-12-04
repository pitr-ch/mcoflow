MCOflow
=======

Proof of concept of using
[Dynflow](https://www.github.com/iNecas/dynflow) as backend for
remote commands via MCollective.

Installation
------------

```bash
git clone git@github.com:iNecas/mcoflow.git
cd mcoflow
bundle install
bundle exec rackup
```

By default it's expected your host is configured as MCollective
admin (using ~/.mcollective config file). It requires the ActiveMQ
connector to be configured (see mcollective.cfg.example file for
inspiration). It might work with RabbitMQ connector as well, it's
known it's not working with STOMP connector, as MCollective doesn't
support `reply_to` feature in this setup.

Usage
-----

Go to `http://localhost:9292`

Fill in the hostname with one that is connected to MCollective.

The param is the field to enter data to the MCollective action.
The usage differs based on triggered action:

  1. Install, Uninstall

     The param is expected to be a single package name to be installed/removed

  2. Restart

     The param is expected to be a single service name

  3. Install and restart

     This action is a demonstration of more complex workflow of installing
     multiple packages and restarting the listed services if any of the
     installations succeeds. The format of the param is the following:

     ```
     package1,package2;service1,service2
     ```

     It can be also used to run multiple installations (not including the
     services part)

Once triggered, you can continue on the task details to see the
Dynflow console showing the it's progress.

Explained
---------

[Dynflow](https://www.github.com/iNecas/dynflow) is a library that is
being build to help [the Katello](https://github.com/Katello/katello)
project to handle multiple calls to external services to achieve
something better.

The workflow base of this project makes it easy
to recover when something goes wrong, it also allows to easily
delegate some action to external services (not blocking the thread
on the workflow side) and waking the process again when some external
event occurs (might be a message on a bus, some change detected by
polling, it depends on the use-case). It also provides an interface
for getting the status and progress and results of the execution.

Dynflow also makes it easy to run the actions concurrently as well
as chaining them using the output from one in the input of other.

The MCollective actions are modeled with `Mcoflow::Action`, where the
`run` method performs the execution itself. This is the interface
`Dynflow` expects to run build the process properly.

After the action is run, it's suspended and the
`Mcoflow::Connectors::MCollective` listens for the replies on the
message bus. Once the reply is there, it wakes up the action the the
process continues in execution.

In more complicated cases (such as
`Mcoflow::Actions::InstallAndRestart`), the action plans another
actions to be executed as part of it. You can also notice that the
output from the install actions is passed to the input of the
restarts. The important thing here is, that nothing is executed in the
`plan` method, the execution plan is just prepared. After planning is
over, the run methods are executed using the Dynflow capabilities.

LICENSE
-------

MIT
