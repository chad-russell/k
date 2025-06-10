#!/bin/bash

# PostgreSQL Cluster Management Script
set -e

NAMESPACE="postgres-system"
CLUSTER_NAME="postgres-cluster"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper function for colored output
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Function to show usage
usage() {
    echo "PostgreSQL Cluster Management Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  status      - Show cluster status"
    echo "  pods        - List all PostgreSQL pods"
    echo "  logs        - Show logs from primary pod"
    echo "  connect     - Connect to PostgreSQL as app user"
    echo "  psql        - Connect to PostgreSQL as superuser"
    echo "  backup      - Trigger manual backup"
    echo "  backups     - List available backups"
    echo "  failover    - Test failover by deleting primary pod"
    echo "  secrets     - Show connection information"
    echo "  monitor     - Watch cluster events"
    echo ""
}

# Check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        error "kubectl is not installed or not in PATH"
    fi
}

# Check if namespace exists
check_namespace() {
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        error "Namespace $NAMESPACE does not exist"
    fi
}

# Show cluster status
show_status() {
    log "Checking cluster status..."
    
    echo -e "\n${BLUE}Cluster Status:${NC}"
    kubectl get cluster "$CLUSTER_NAME" -n "$NAMESPACE" 2>/dev/null || warn "Cluster not found"
    
    echo -e "\n${BLUE}Pods:${NC}"
    kubectl get pods -n "$NAMESPACE" -l postgresql="$CLUSTER_NAME" 2>/dev/null || warn "No pods found"
    
    echo -e "\n${BLUE}Services:${NC}"
    kubectl get svc -n "$NAMESPACE" | grep postgres-cluster 2>/dev/null || warn "No services found"
    
    echo -e "\n${BLUE}Storage:${NC}"
    kubectl get pvc -n "$NAMESPACE" 2>/dev/null || warn "No PVCs found"
}

# Show pod logs
show_logs() {
    local primary_pod
    primary_pod=$(kubectl get pods -n "$NAMESPACE" -l postgresql="$CLUSTER_NAME",role=primary -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [[ -z "$primary_pod" ]]; then
        # Fallback to first available pod
        primary_pod=$(kubectl get pods -n "$NAMESPACE" -l postgresql="$CLUSTER_NAME" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    fi
    
    if [[ -z "$primary_pod" ]]; then
        error "No PostgreSQL pods found"
    fi
    
    log "Showing logs from pod: $primary_pod"
    kubectl logs "$primary_pod" -n "$NAMESPACE" --tail=100 -f
}

# Connect to PostgreSQL
connect_psql() {
    local user="$1"
    local db="${2:-app_db}"
    
    # Get the primary pod
    local primary_pod
    primary_pod=$(kubectl get pods -n "$NAMESPACE" -l postgresql="$CLUSTER_NAME",role=primary -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [[ -z "$primary_pod" ]]; then
        # Fallback to first available pod
        primary_pod=$(kubectl get pods -n "$NAMESPACE" -l postgresql="$CLUSTER_NAME" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    fi
    
    if [[ -z "$primary_pod" ]]; then
        error "No PostgreSQL pods found"
    fi
    
    log "Connecting to PostgreSQL as $user on pod: $primary_pod"
    kubectl exec -it "$primary_pod" -n "$NAMESPACE" -- psql -U "$user" -d "$db"
}

# Trigger manual backup
trigger_backup() {
    local timestamp
    timestamp=$(date +%Y%m%d%H%M%S)
    
    log "Triggering manual backup: backup-$timestamp"
    kubectl annotate cluster "$CLUSTER_NAME" -n "$NAMESPACE" \
        cnpg.io/backup="backup-$timestamp" --overwrite
    
    log "Backup annotation added. Monitor progress with: kubectl get backup -n $NAMESPACE"
}

# List backups
list_backups() {
    log "Available backups:"
    kubectl get backup -n "$NAMESPACE" 2>/dev/null || warn "No backups found"
}

# Test failover
test_failover() {
    warn "This will delete the primary pod to test automatic failover!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        log "Cancelled"
        return
    fi
    
    local primary_pod
    primary_pod=$(kubectl get pods -n "$NAMESPACE" -l postgresql="$CLUSTER_NAME",role=primary -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [[ -z "$primary_pod" ]]; then
        error "No primary pod found"
    fi
    
    log "Deleting primary pod: $primary_pod"
    kubectl delete pod "$primary_pod" -n "$NAMESPACE"
    
    log "Monitoring failover process..."
    kubectl get pods -n "$NAMESPACE" -l postgresql="$CLUSTER_NAME" -w
}

# Show connection secrets
show_secrets() {
    log "Connection Information:"
    
    echo -e "\n${BLUE}Services:${NC}"
    echo "Read-Write: postgres-cluster-rw.$NAMESPACE.svc.cluster.local:5432"
    echo "Read-Only:  postgres-cluster-ro.$NAMESPACE.svc.cluster.local:5432"
    echo "Database:   app_db"
    
    echo -e "\n${BLUE}Credentials:${NC}"
    echo "Username: app_user"
    
    if kubectl get secret postgres-credentials -n "$NAMESPACE" &> /dev/null; then
        echo -n "Password: "
        kubectl get secret postgres-credentials -n "$NAMESPACE" -o jsonpath='{.data.app_password}' | base64 -d
        echo ""
    else
        warn "Secrets not found - cluster may not be deployed yet"
    fi
}

# Monitor cluster events
monitor_events() {
    log "Monitoring cluster events (Ctrl+C to stop)..."
    kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' -w
}

# Main script logic
main() {
    check_kubectl
    
    case "${1:-}" in
        "status")
            check_namespace
            show_status
            ;;
        "pods")
            check_namespace
            kubectl get pods -n "$NAMESPACE" -l postgresql="$CLUSTER_NAME"
            ;;
        "logs")
            check_namespace
            show_logs
            ;;
        "connect")
            check_namespace
            connect_psql "app_user"
            ;;
        "psql")
            check_namespace
            connect_psql "postgres"
            ;;
        "backup")
            check_namespace
            trigger_backup
            ;;
        "backups")
            check_namespace
            list_backups
            ;;
        "failover")
            check_namespace
            test_failover
            ;;
        "secrets")
            check_namespace
            show_secrets
            ;;
        "monitor")
            check_namespace
            monitor_events
            ;;
        *)
            usage
            ;;
    esac
}

main "$@" 