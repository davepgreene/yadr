OLD_ASG=$1
NEW_ASG=$2
NUM=$3
REGION=$4
ID=$5

# Detach instance
echo "aws autoscaling update-auto-scaling-group --auto-scaling-group-name \"$OLD_ASG\" --min-size 0 --region \"$REGION\""
aws autoscaling update-auto-scaling-group --auto-scaling-group-name "$OLD_ASG" --min-size 0 --region "$REGION"
sleep 2
echo "aws autoscaling detach-instances --auto-scaling-group-name \"$OLD_ASG\" --instance-ids \"$ID\" --should-decrement-desired-capacity --region \"$REGION\""
aws autoscaling detach-instances --auto-scaling-group-name "$OLD_ASG" --instance-ids "$ID" --should-decrement-desired-capacity --region "$REGION"

echo "Sleeping 30 seconds to allow instance to detach"
sleep 30

# Attach instance
echo "aws autoscaling update-auto-scaling-group --auto-scaling-group-name \"$NEW_ASG\" --max-size \"$NUM\" --region \"$REGION\""
aws autoscaling update-auto-scaling-group --auto-scaling-group-name "$NEW_ASG" --max-size "$NUM" --region "$REGION"
sleep 2
echo "aws autoscaling attach-instances --auto-scaling-group-name \"$NEW_ASG\" --instance-ids \"$ID\" --region \"$REGION\""
aws autoscaling attach-instances --auto-scaling-group-name "$NEW_ASG" --instance-ids "$ID" --region "$REGION"
