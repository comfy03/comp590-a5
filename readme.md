# comp590-A4

# Chain Servers with Dynamic Updates in Erlang

## Overview

This Erlang program demonstrates a chain of three servers that communicate through message passing. Each server specializes in handling specific types of messages, and unhandled messages are passed to the next server in the chain. The program also allows dynamic updates, enabling servers to replace themselves with new instances.

- **`serv1`**: Handles arithmetic operations such as addition and subtraction.
- **`serv2`**: Processes lists of numbers and computes their sum.
- **`serv3`**: Manages error messages and keeps track of unhandled messages.

## Functions

- **`start/0`**: Initializes the server chain and starts the interactive input loop.
- **`serv1/2`**: Handles arithmetic operations (`add`, `sub`), processes update requests, and forwards unhandled messages to `serv2`.
- **`serv2/1`**: Processes lists of integers, computes their sum, and forwards unhandled messages to `serv3`.
- **`serv3/1`**: Handles error messages, counts unhandled messages, and processes updates.
- **`message_loop/1`**: Manages interactive user input, routing messages to `serv1` and handling updates dynamically.

### Update Function

The `update` function allows a server to replace itself with a new instance running the latest version of its code. When a server receives an `update` message, it spawns a new process with the updated code, informs the `message_loop` of the new PID, and terminates the old process. This ensures that updates are isolated to the specific server receiving the message, without affecting other servers in the chain.