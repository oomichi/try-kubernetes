package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
)

// Standard HTTP methods: https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md#path-item-object
func isHttpMethod(method string) bool {
	methods := []string{"get", "put", "post", "delete", "options", "head", "patch"}
	for _, valid_method := range methods {
		if method == valid_method {
			return true
		}
	}
	return false
}

func parseOpenAPI() {
	var decode_data interface{}

	bytes, err := ioutil.ReadFile("swagger.json")
	if err != nil {
		log.Fatal(err)
	}
	if err := json.Unmarshal(bytes, &decode_data); err != nil {
		log.Fatal(err)
	}
	for key, data := range decode_data.(map[string]interface {}) {
		if key != "paths" {
			continue
		}
		for api_url, api_spec := range data.(map[string]interface {}) {
			for api_method, _ := range api_spec.(map[string]interface {}) {
				if !isHttpMethod(api_method) {
					continue
				}
				fmt.Printf("%s: %s\n", api_url, api_method)
			}
		}
	}
}

func main() {
	parseOpenAPI()
}
