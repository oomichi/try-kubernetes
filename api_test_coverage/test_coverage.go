package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"regexp"
	"strings"
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

type API struct {
	Method string
	Url string
}

type Apis []API

// /apis/extensions/v1beta1/namespaces/{namespace}/networkpolicies/{name}
// /apis/extensions/v1beta1/namespaces/\S+/networkpolicies/\S+
var re_openapi = regexp.MustCompile(`({\S+})`)

func parseOpenAPI() Apis {
	var decode_data interface{}
	var apis_openapi Apis

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
				api_method := strings.ToUpper(api_method)
				api_url = re_openapi.ReplaceAllLiteralString(api_url, `\S+`)
				api := API {
					Method: api_method,
					Url: api_url,
				}
				apis_openapi = append(apis_openapi, api)
			}
		}
	}
	//fmt.Printf("%s", apis_openapi)
	return apis_openapi
}

// Request: POST https://172.27.138.84:6443/api/v1/namespaces
var re_api_log = regexp.MustCompile(`Request: (\S+) (\S+)`)

func parseApiLog() Apis {
	var fp *os.File
	var apis_log Apis
	var err error

	//TODO: Make the file path selectable
	fp, err = os.Open("Conformance-rest-op.log")
	if err != nil {
		log.Fatal(err)
	}
	defer fp.Close()

	reader := bufio.NewReaderSize(fp, 4096)
	for line := ""; err == nil; line, err = reader.ReadString('\n') {
		result := re_api_log.FindSubmatch([]byte(line))
		if len(result) == 0 {
			continue
		}
		method := strings.ToUpper(string(result[1]))
		url := string(result[2])
		api := API {
			Method: method,
			Url: url,
		}
		//TODO: Remove duplicated entries for speed
		apis_log = append(apis_log, api)
	}
	//fmt.Printf("%s", apis_log)
	return apis_log
}

func main() {
	var found bool
	var num_found int
	var num_not_found int

	apis_openapi := parseOpenAPI()
	apis_logs := parseApiLog()

	num_found = 0
	num_not_found = 0
	for _, openapi := range apis_openapi {
		reg := regexp.MustCompile(openapi.Url)
		found = false
		for _, log := range apis_logs {
			if openapi.Method != log.Method {
				continue
			}
			if reg.MatchString(log.Url) {
				//fmt.Printf("found: %s %s\n", openapi.Method, openapi.Url)
				found = true
				num_found++
				break
			}
		}
		if found == false {
			fmt.Printf("The API(%s %s) is not found in e2e operation log.\n", openapi.Method, openapi.Url)
			num_not_found++
		}
	}
	fmt.Printf("num_found: %d\n", num_found)
	fmt.Printf("num_not_found: %d\n", num_not_found)
}
