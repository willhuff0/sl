#pragma once

#if defined(__cplusplus)
extern "C" {
#endif

typedef struct {
    float x;
    float y;
    float z;
} Vector3;
typedef struct {
    float x;
    float y;
    float z;
    float w;
} Quaternion;

typedef void Transform;

typedef void CollisionShape;
typedef void RigidBody;

// World
void World_New();

void World_SetGravity(float x, float y, float z);

void World_AddRigidBody(RigidBody* rigidBody);

void World_StepSimulation(float timeStep, int maxSubSteps, float fixedTimeStep);
//

// Transform
Vector3 Transform_GetOrigin(Transform* transform);
Quaternion Transform_GetRotation(Transform* transform);

void Transform_SetIdentity(Transform* transform);
void Transform_SetOrigin(Transform* transform, Vector3 origin);
void Transform_SetRotation(Transform* transform, Quaternion rotation);

void Transform_GetOpenGLMatrix(Transform* transform, float* matrix);
void Transform_SetFromOpenGLMatrix(Transform* transform, float* matrix);
//

// btCollisionShape
CollisionShape* CollisionShape_NewBoxShape(Vector3 halfExtents);

void CollisionShape_CalculateLocalInertia(CollisionShape* self, float mass, Vector3* localInertia);
//

// RigidBody
RigidBody* RigidBody_New(float mass, Transform* transform, CollisionShape* shape, Vector3 localInertia);

void RigidBody_GetWorldTransform(RigidBody* self, Transform* transform);
void RigidBody_SetWorldTransform(RigidBody* self, Transform* transform);
//

#if defined(__cplusplus)
}
#endif