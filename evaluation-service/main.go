package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
)

func respond(w http.ResponseWriter, status int, payload map[string]string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8004"
	}
	http.HandleFunc("/health", func(w http.ResponseWriter, _ *http.Request) {
		respond(w, http.StatusOK, map[string]string{"service": "evaluation-service", "status": "ok"})
	})
	http.HandleFunc("/evaluate", func(w http.ResponseWriter, _ *http.Request) {
		respond(w, http.StatusOK, map[string]string{"service": "evaluation-service", "result": "enabled"})
	})
	http.HandleFunc("/", func(w http.ResponseWriter, _ *http.Request) {
		respond(w, http.StatusOK, map[string]string{"service": "evaluation-service"})
	})
	log.Printf("evaluation-service listening on :%s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
