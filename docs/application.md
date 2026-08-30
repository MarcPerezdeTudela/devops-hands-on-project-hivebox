# Application

HiveBox is a FastAPI service whose application object is `src.main:app`. It
averages recent ambient-temperature readings from configured openSenseMap
senseBoxes and exposes version and temperature endpoints for beekeepers.

`HIVEBOX_SENSEBOX_IDS` replaces the default senseBox list. Supplied values are
validated strictly at startup so an invalid configuration never falls back
silently to the defaults. The same application runs locally and in the Docker
image used by Kubernetes.
