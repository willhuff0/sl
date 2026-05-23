#include "bullet3.h"

#include "btBulletDynamicsCommon.h"

static btDefaultCollisionConfiguration* collisionConfiguration;
static btCollisionDispatcher* dispatcher;
static btBroadphaseInterface* overlappingPairCache;
static btSequentialImpulseConstraintSolver* solver;
static btDiscreteDynamicsWorld* dynamicsWorld;

// World
void World_New() {
    collisionConfiguration = new btDefaultCollisionConfiguration();
    dispatcher = new btCollisionDispatcher(collisionConfiguration);
    overlappingPairCache = new btDbvtBroadphase();
    solver = new btSequentialImpulseConstraintSolver();
    dynamicsWorld = new btDiscreteDynamicsWorld(dispatcher, overlappingPairCache, solver, collisionConfiguration);
}

void World_SetGravity(float x, float y, float z) {
    dynamicsWorld->setGravity(btVector3(x, y, z));
}

void World_AddRigidBody(RigidBody* rigidBody) {
    dynamicsWorld->addRigidBody(static_cast<btRigidBody*>(rigidBody));
}

void World_StepSimulation(float timeStep, int maxSubSteps, float fixedTimeStep) {
    dynamicsWorld->stepSimulation(timeStep, maxSubSteps, fixedTimeStep);
}
//

// transform
Vector3 Transform_GetOrigin(Transform* transform) {
    auto result = static_cast<btTransform*>(transform)->getOrigin();
    return {
        .x = result.getX(),
        .y = result.getY(),
        .z = result.getZ(),
    };
}
Quaternion Transform_GetRotation(Transform* transform) {
    auto result = static_cast<btTransform*>(transform)->getRotation();
    return {
        .x = result.getX(),
        .y = result.getY(),
        .z = result.getZ(),
        .w = result.getW(),
    };
}

void Transform_SetIdentity(Transform* transform) {
    static_cast<btTransform*>(transform)->setIdentity();
}
void Transform_SetOrigin(Transform* transform, Vector3 origin) {
    static_cast<btTransform*>(transform)->setOrigin(btVector3(origin.x, origin.y, origin.z));
}
void Transform_SetRotation(Transform* transform, Quaternion rotation) {
    static_cast<btTransform*>(transform)->setRotation(btQuaternion(rotation.x, rotation.y, rotation.z, rotation.w));
}

void Transform_GetOpenGLMatrix(Transform* transform, float* matrix) {
    static_cast<btTransform*>(transform)->getOpenGLMatrix(matrix);
}
void Transform_SetFromOpenGLMatrix(Transform* transform, float* matrix) {
    static_cast<btTransform*>(transform)->setFromOpenGLMatrix(matrix);
}
//

// btCollisionShape
CollisionShape* CollisionShape_NewBoxShape(Vector3 halfExtents) {
    return new btBoxShape(btVector3(halfExtents.x, halfExtents.y, halfExtents.z));
}

void CollisionShape_CalculateLocalInertia(CollisionShape* self, float mass, Vector3* localInertia) {
    btVector3 localInertiaResult(0.0, 0.0, 0.0);
    static_cast<btCollisionShape*>(self)->calculateLocalInertia(mass, localInertiaResult);
    localInertia->x = localInertiaResult.getX();
    localInertia->y = localInertiaResult.getY();
    localInertia->z = localInertiaResult.getZ();
}
//

// btRigidBody
RigidBody* RigidBody_New(float mass, Transform* transform, CollisionShape* shape, Vector3 localInertia) {
    btDefaultMotionState* motionState = new btDefaultMotionState(*static_cast<btTransform*>(transform));
    btRigidBody::btRigidBodyConstructionInfo rigidBodyInfo(mass, motionState, static_cast<btCollisionShape*>(shape), btVector3(localInertia.x, localInertia.y, localInertia.z));
    return new btRigidBody(rigidBodyInfo);
}

void RigidBody_GetWorldTransform(RigidBody* self, Transform* transform) {
    static_cast<btRigidBody*>(self)->getMotionState()->getWorldTransform(*static_cast<btTransform*>(transform));
}
void RigidBody_SetWorldTransform(RigidBody* self, Transform* transform) {
    static_cast<btRigidBody*>(self)->getMotionState()->setWorldTransform(*static_cast<btTransform*>(transform));
}
//
