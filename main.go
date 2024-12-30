package main

import (
	"flag"
	"fmt"

	log "github.com/sirupsen/logrus"

	"os/user"
	"strconv"

	"github.com/docker/go-plugins-helpers/volume"
)

var (
	root = flag.String("root", "/mnt/moosefs", "Host's base directory where volumes are created")
	verbose    = flag.Bool("verbose", false, "Enable verbose logging")
)

func main() {
	flag.Parse()

	if *verbose {
		log.SetLevel(log.DebugLevel)
	} else {
		log.SetLevel(log.InfoLevel)
	}

	u, _ := user.Lookup("root")
	gid, _ := strconv.Atoi(u.Gid)

	d, err := newMooseFSDriver(*root)
	if err != nil {
		log.Fatalf("Failed to initialize driver: %v", err)
	}
	h := volume.NewHandler(d)
	fmt.Println(h.ServeUnix("moosefs", gid))
}
