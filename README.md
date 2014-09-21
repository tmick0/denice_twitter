# denice_twitter

a port of [denice](https://github.com/wetfish/denice)'s chatter algorithm to twitter's api

### behavior

denice will read the content of your twitter timeline, and create a markov-chain
based dictionary from it. then, denice can post dumb reconstructed tweets based on
the dictionary.

you will need to make a twitter api key (and client credentials) for the account
denice will be using.

a demo instance is running as [@denice_wetfish](http://twitter.com/denice_wetfish).

### requirements

- lua >=5.1
- luasql (mysql)
- [luaoauth](https://github.com/ignacio/LuaOAuth)

### config

edit denice.lua, and just fill in the sql and twitter credentials at the top of the file.

### running

just call `lua denice.lua <mode>`.  
choose from these 4 modes: *fetch*, *post*, *test*, and *stats*.

- fetch will parse the latest tweets from your timeline into the database dictionary
- post will post a tweet based on the content of the dictionary
- test will print a candidate tweet to stdout
- stats will print information about the content of the database

you can set up a cronjob to call 'fetch' and 'post' at whatever intervals you want, e.g.
fetch every 5 minutes and post every 15 minutes.

### contact

both the twitter and irc implementations of denice are maintained by lq.  
email: root at lo dot calho dot st
