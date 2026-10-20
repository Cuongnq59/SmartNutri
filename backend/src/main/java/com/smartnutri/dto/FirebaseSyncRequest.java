package com.smartnutri.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FirebaseSyncRequest {
    private String firebaseUid;
    private String email;
    private String fullName;
    private String photoUrl;
}
