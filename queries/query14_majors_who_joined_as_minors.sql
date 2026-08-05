-- Requirement 14: major members who have been members since they were minors, sorted by location then age.
-- Both facts come from DOB. memberType is the type today, typeAtRegistration the type on the registration date. A stored memberType column would be wrong for every member who has had a birthday since joining.

SELECT
    vms.memberID        AS clubMembershipNumber,
    vms.firstName,
    vms.lastName,
    vms.status,
    vms.registrationDate AS dateJoined,
    vms.age,
    vms.phone,
    vms.email,
    vms.currentLocationName
FROM v_MemberStatus vms
WHERE vms.memberType         = 'Major'
  AND vms.typeAtRegistration = 'Minor'
ORDER BY vms.currentLocationName ASC, vms.age ASC;
