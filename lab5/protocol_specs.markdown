## Protocol Specifications

### General Info
* Language: Elixir
* Libs/Behaviours: GenServer, :gen_tcp
* Code Architecture:
  * server.ex
  * client.ex

### Message Format
* A message starts with ` / `
* All the messages contain alphanumeric characters ` A-Za-z0-9 ` 
* If a command accepts parameters, they are separated by spaces
* If the server receives an unknown command, it returnes ` UNKNOWN COMMAND `

### Commands Accepted by Server
* ` /help ` - displays a help message
* ` /hello <string> ` - reports back to the client the string massed after ` /hello `
* ` /time ` - returns the current time
* ` /random <n1> <n2> ` - takes two integer numbers and returns a random number between them
* `/coinflip ` - returns a random integer between 0 and 1

### Examples
```
  >/help
  Available commands:
      * /hello 'string' -- returns the message after greeting
      * /time -- returns the current time
      * /random 'n1' 'n2' -- returns a random number between n1 and n2
      * /coinflip -- reuturns 0 or 1
      
  >/hello My name is Bane
  My name is Bane
  
  >/time
  2018-05-02 22:28:44.223054Z
  
  >/coinflip
  0
  
  >/random 123 56344245
  123424
  
```
