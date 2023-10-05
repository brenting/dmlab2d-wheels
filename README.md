# Repository
This repo produces wheels of the [dmlab2d](https://github.com/google-deepmind/lab2d) package for CentOS. 2 wheels are already build and can be found in the `wheels` directory:
- A Python 3.9, CentOS 7 wheel
- A Python 3.10, CentOS 7 wheel

The dockerfile that created these wheels is also included and can be used to compile additional wheels (see next section).

# Build command
```bash
docker build --pull --rm -f "dockerfile" -t dmlab2d-wheel -o wheels .
```
This command will build the dockerfile and store the obtain wheel in the `wheel` directory.