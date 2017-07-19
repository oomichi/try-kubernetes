package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
)

func main() {
	var decode_data interface{}

	fmt.Println("hello world")

	bytes, err := ioutil.ReadFile("swagger.json")
	if err != nil {
		log.Fatal(err)
	}
	if err := json.Unmarshal(bytes, &decode_data); err != nil {
		log.Fatal(err)
	}
	for key, data := range decode_data.(map[string]interface {}) {
		var d = data.(string)
		fmt.Printf("%s: %s\n", key, d)
		break
	}
}
