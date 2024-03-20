REPORT FOR SPEC 4 PART B

How is your implementation of data sequencing and retransmission different from traditional TCP?

This way of data sequencing and retruansmission is different from TCP as it is less reliable, doesn't have flow control, windowing or
congestion controlmechanisms. There is also no 3-way handshake for connection establishment or 4-way handshake for connection termination.
There is also no complex header with flags like SYN etc. and as such it cannot implement error handling (checksum etc.) like TCP does.


How can you extend your implementation to account for flow control (https://en.wikipedia.org/wiki/Transmission_Control_Protocol#Flow_control)? You may ignore deadlocks. 

TCP has a sliding window protocol to implement flow control, i.e. to avoid the sender sending data too fast. The receiver has a receive
window for which the server can only send that much data and must wait for an ACK bit in return, and if the receive window is 0 it will
protect from a deadlock situation.

Without considering the deadlock situation, in this code I would define a receive window on the receiver side, with an array of packets
of size of the receive window, and a count to keep track of incoming packets. Once all packets of window size are received, we send
and ACK bit back to the server.
On the server side we can keep a window of the same size and a similar array. In the sender loop, we check if there is more space in the 
window before adding a new packet to send. Once all the packets of window size have been sent, we will wait until a receive window 
acknowledgement was sent by receiver. Once there is an acknowledgement, we clear the array and keep adding the rest of the data in 
chunks of window size, until the data is fully sent.