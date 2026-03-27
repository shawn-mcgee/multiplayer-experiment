### Motivation

I have a deep desire to create a game and to do it with friends. A part of me believes that if I can scaffold a working multiplayer workflow then getting friends together to goof around and author content will be *"easy"*. Getting this project working is 

### Objectives

- [X] Automagically publish to the web in minutes
- Connect players with painless matchmaking (Maybe Trystero?)
- Develop a workflow for quickly testing multiplayer features locally

### Features

- [ ] Lobby which limits the number of connections
- [ ] Lobby with user roles (host, guest, spectator)
- [ ] Host controls to kick users
- [ ] Users can identify themselves (e.g. display name)
- [ ] Users can communicate (e.g. text chat)
- [ ] Host controls to mute users
- [ ] Players can move around a shared environment
- [ ] Players can interact with a shared environment (e.g. build, destroy, etc)
- [ ] Players can interact with each other (e.g. bump, attack, etc)
- [ ] Spectators can observe the game
- [ ] Spectators can move (their view) around the shared environment

### Terms

- **user** - any peer
- **host** - the authoritative peer
- **guest** - any non-authoritative peer
- **player** - any peer playing the game
- **spectator** - any peer observing the game



### Automagically Building and Publishing to the Web

Found this neat project for generating artifacts for Mac, Windows, Linux, and the Web - [abarichello/godot-ci](https://github.com/abarichello/godot-ci)

I had to replace the following line in each job

```yaml
jobs:
  export-windows:
    # ...
    container:
      image: barichello/godot-ci:4.3 # <-- Update this line with the correct version of Godot for your project
    # ...
```

I had to configure exports for Mac, Windows, Linux, and the Web


The Mac export required that I enable `rendering/textures/vram_compression/import_etc2_astc` in the project settings (it is not visible until the "Advanced Settings" switch is toggled on)


The Linux export needed renaming. By default the Linux template is simply called `Linux`; however, the workflow expects the Linux template to be called `Linux/X11`. It is possible to change the name of the Linux template in the workflow, but I opted to change it in the project settings.


The Web export required I update the repository settings to allow read *and write* access to workflows via `Repository > Settings > Actions > General > Workflow permissions`


The Web export required I update the repository settings to deploy from the `gh-pages` branch via `Repository > Settings > Pages > Github Pages > Build and deployment > Source`
