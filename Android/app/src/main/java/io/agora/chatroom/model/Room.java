package io.agora.chatroom.model;

import java.io.Serializable;
import java.util.List;

public class Room implements Serializable {
    private String objectId;
    private String channelName;
    private User anchorId;

    private List<Member> speakers;
    private int members = 0;

    public String getObjectId() {
        return objectId;
    }

    public void setObjectId(String objectId) {
        this.objectId = objectId;
    }

    public String getChannelName() {
        return channelName;
    }

    public void setChannelName(String channelName) {
        this.channelName = channelName;
    }

    public User getAnchorId() {
        return anchorId;
    }

    public void setAnchorId(User anchorId) {
        this.anchorId = anchorId;
    }

    public List<Member> getSpeakers() {
        return speakers;
    }

    public void setSpeakers(List<Member> speakers) {
        this.speakers = speakers;
    }

    public int getMembers() {
        return members;
    }

    public void setMembers(int members) {
        this.members = members;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        Room room = (Room) o;

        return objectId.equals(room.objectId);
    }

    @Override
    public int hashCode() {
        return objectId.hashCode();
    }

    @Override
    public String toString() {
        return "Room{" +
                "objectId='" + objectId + '\'' +
                ", channelName='" + channelName + '\'' +
                ", anchorId=" + anchorId +
                '}';
    }
}