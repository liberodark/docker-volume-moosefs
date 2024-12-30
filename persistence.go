package main

import (
	"encoding/json"
	"io/ioutil"
	"os"
	"path/filepath"
)

const stateFile = "/var/lib/docker-volume-moosefs/state.json"

type State struct {
	Mounts map[string]*moosefsMount `json:"mounts"`
}

func ensureStateDir() error {
	dir := filepath.Dir(stateFile)
	return os.MkdirAll(dir, 0755)
}

func (d *moosefsDriver) saveState() error {
	d.m.Lock()
	defer d.m.Unlock()

	if err := ensureStateDir(); err != nil {
		return err
	}

	state := State{
		Mounts: d.mounts,
	}

	data, err := json.Marshal(state)
	if err != nil {
		return err
	}

	return ioutil.WriteFile(stateFile, data, 0644)
}

func (d *moosefsDriver) loadState() error {
	d.m.Lock()
	defer d.m.Unlock()

	data, err := ioutil.ReadFile(stateFile)
	if os.IsNotExist(err) {
		// No state file exists yet, start with empty state
		return nil
	}
	if err != nil {
		return err
	}

	var state State
	if err := json.Unmarshal(data, &state); err != nil {
		return err
	}

	d.mounts = state.Mounts
	return nil
}
