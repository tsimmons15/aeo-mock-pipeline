variable "pubsub_details" { 
    type        = object({
        topic_name      = string
        browse_event    = string
        cart_event      = string
        commerce_event  = string
        return_event    = string
        inventory_event = string
    })
#    default     = ""
    description = "The pubsub details to be stood up"
}