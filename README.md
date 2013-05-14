Raft Consensus Algorithm using Bloom
===

## How to Run Test Suite

Testing interaction between multiple Nodes running simultaneously  

    ruby -I . test_node.rb


Testing a single Node in the 3 different node states (Follower, Candidate, Leader)  

    ruby -I . test_follower.rb  
    ruby -I . test_candidate.rb  
    ruby -I . test_leader.rb
    
## Structure
Our implementation of raft is split into 4 main modules. The first is the Node module, which holds 
all state and passes that state to each of the other 3 main modules. Those modules are Follower, 
Candidate, and Leader and contain logic for both leader election and appending entries to the log.

## Inner Node Protocol 
Protocol between Node module and the 3 node state modules (Follower, Candidate, and Leader)

## Node Protocol
Protocol between nodes as well as how an external client would send commands to the system.  

```
interface input,  :command
```
Input for external client to send command they want persisted to the log (the entry_id must be globally unique)

```
interface output,  :command_ack
```
Output to external client acknowledging the command successfully committed to the log
