## Analyzing a packet

1. Packet data as a hex stream:
```
4d5455794e6a51354f4445304e4463774d58786c4d5467774d4755344d43316a596a67324c5451324d6a49744f4451794d79316d4e4745794d7a4d794d5451794d4468384f6d46736248786c656e41775a56684362456c4563485a6962586877596d315663306c456344466a4d6c5a35596d31476446705451576c6b52326835576c645661575a525054303d
```
2. Packet data in base64:
```
MTUyNjQ5ODE0NDcwMXxlMTgwMGU4MC1jYjg2LTQ2MjItODQyMy1mNGEyMzMyMTQyMDh8OmFsbHxlenAwZVhCbElEcHZibXhwYm1Vc0lEcDFjMlZ5Ym1GdFpTQWlkR2h5WldVaWZRPT0=
```

3. Decoded base64 data:
```
1526498144701|e1800e80-cb86-4622-8423-f4a233214208|:all|ezp0eXBlIDpvbmxpbmUsIDp1c2VybmFtZSAidGhyZWUifQ==
```

	* 1526498144701 - time in milliseconds representing Wed May 16 2018 19:15:44 UTC
	* e1800e80-cb86-4622-8423-f4a233214208 - user unique identifier 
	* :all - field showing that the packet has to be broadcasted to all created users
	* ezp0eXBlIDpvbmxpbmUsIDp1c2VybmFtZSAidGhyZWUifQ== - another base64 string that resunts into {:type :online, :username "three"}


## Registering a User from outside the application

1. Let the time be the same as in the analyzed packet
2. Change the UUID to be a new unique one, for example ``` e2800e80-cb86-4622-8423-f4a233214208 ```
3. Create a new username, for example ``` {:type :online, :username "fake_user"} ```
4. Encode it to base64 - ``` ezp0eXBlIDpvbmxpbmUsIDp1c2VybmFtZSAiZmFrZV91c2VyIn0= ```
5. Reassemble the packet structure - ``` 1526498144701|e2800e80-cb86-4622-8423-f4a233214208|:all|ezp0eXBlIDpvbmxpbmUsIDp1c2VybmFtZSAiZmFrZV91c2VyIn0= ```
6. Encode this string to base64 - ``` MTUyNjQ5ODE0NDcwMXxlMjgwMGU4MC1jYjg2LTQ2MjItODQyMy1mNGEyMzMyMTQyMDh8OmFsbHxlenAwZVhCbElEcHZibXhwYm1Vc0lEcDFjMlZ5Ym1GdFpTQWlabUZyWlY5MWMyVnlJbjA9 ```
7. Send the packet using Packet Sender; use the destination IP address and port number from the description in WireShark

## Understanding the packets when sending messages

1. The first packet as a base64 string:
```
1526505324501|2540a3e4-4d26-40dc-aac1-27f1d9e01c43|e2800e80-cb86-4622-8423-f4a233214208|ezp0eXBlIDpjaGF0LCA6dHh0ICJoZWxsbyB0aGVyZSwgdGhpcyBpcyBhIG1lc3NhZ2VcbiJ9
```
2. ``` 2540a3e4-4d26-40dc-aac1-27f1d9e01c43 ``` - UUID of user ``` one ```
3. ``` e2800e80-cb86-4622-8423-f4a233214208 ``` - UUID of user ``` fake_user ```
4. ``` ezp0eXBlIDpjaGF0LCA6dHh0ICJoZWxsbyB0aGVyZSwgdGhpcyBpcyBhIG1lc3NhZ2VcbiJ9``` - ```{:type :chat, :txt "hello there, this is a message\n"}```

5. The second packet can be translated just the same, the difference being the data portion - ```{:type :delivered}```

## Sending a message from outside the application

1. Use ```fake_user``` UUID as sender -  ``` e2800e80-cb86-4622-8423-f4a233214208 ```
2. Use ```one``` UUID as receiver -  ``` 2540a3e4-4d26-40dc-aac1-27f1d9e01c43 ```
3. Encode a message to base64:
```{:type :chat, :txt "I AM SENDING A FAKE MESSAGE"}``` - ```ezp0eXBlIDpjaGF0LCA6dHh0ICJJIEFNIFNFTkRJTkcgQSBGQUtFIE1FU1NBR0UifQ==```
4. Assemble a new base64 packet, using the old time:
```
MTUyNjUwNTMyNDUwMXxlMjgwMGU4MC1jYjg2LTQ2MjItODQyMy1mNGEyMzMyMTQyMDh8MjU0MGEzZTQtNGQyNi00MGRjLWFhYzEtMjdmMWQ5ZTAxYzQzfGV6cDBlWEJsSURwamFHRjBMQ0E2ZEhoMElDSkpJRUZOSUZORlRrUkpUa2NnUVNCR1FVdEZJRTFGVTFOQlIwVWlmUT09
```
5. Send the message using PacketSender
