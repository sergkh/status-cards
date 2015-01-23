# status-cards
Language cards in the status bar for OSX

Application randomly shows foreign words and translation in a non-interfering way on the OSX statusbar. 

![Screen shot](https://raw.githubusercontent.com/sergkh/status-cards/master/images/screen.png)

Currently words can be imported from plain text files, where words can be separated by dashes (`—`) or colons (`:`):

```
moniker  —  кличка
commotion  —  суматоха
father-in-law  —  тесть, отчим
```

Note: that hyphen (`-`) can be freely used in word or translation.

Once imported file will be re-read from time to time, so any changes in that file will be added to users dictionary.

Already implemented:
  + importing files and autorefreshing of text files
  + ordering word by views number
  + autostart with system
  
Roadmap:

  - Preferences dialog for managing datasources, settings and dictionaires.
  - Lingualeo integration
  - Separation of different languages

Ready build is [here](https://github.com/sergkh/status-cards/blob/master/builds/status-cards.zip). Just copy it in applicatioons and run.

