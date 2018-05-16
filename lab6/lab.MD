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
	* ```1526498144701``` - time in milliseconds representing Wed May 16 2018 19:15:44 UTC
	* e1800e80-cb86-4622-8423-f4a233214208 - user unique identifier 
	* :all - field showing that the packet has to be broadcasted to all created users
	* ezp0eXBlIDpvbmxpbmUsIDp1c2VybmFtZSAidGhyZWUifQ== - another base64 string that resunts into {:type :online, :username "three"}
