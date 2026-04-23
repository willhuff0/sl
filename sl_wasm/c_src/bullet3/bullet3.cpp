#include "bullet3.h"

#include "bullet3/src/btBulletDynamicsCommon.h"

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
    dynamicsWorld->addRigidBody(rigidBody);
}

void World_StepSimulation(float timeStep, int maxSubSteps, float fixedTimeStep) {
    dynamicsWorld->stepSimulation(timeStep, maxSubSteps, fixedTimeStep);
}
//

// Transform
Vector3 Transform_GetOrigin(Transform* transform) {
    return transform->getOrigin();
}
Quaternion Transform_GetRotation(Transform* transform) {
    return transform->getRotation();
}

void Transform_SetIdentity(Transform* transform) {
    transform->setIdentity();
}
void Transform_SetOrigin(Transform* transform, Vector3 origin) {
    transform->setOrigin(origin);
}
void Transform_SetRotation(Transform* transform, Quaternion rotation) {
    transform->setRotation(rotation);
}

void Transform_GetOpenGLMatrix(Transform* transform, float* matrix) {
    transform->getOpenGLMatrix(matrix);
}
void Transform_SetFromOpenGLMatrix(Transform* transform, float* matrix) {
    transform->setFromOpenGLMatrix(matrix);
}
//

// CollisionShape
CollisionShape* CollisionShape_NewBoxShape(Vector3 halfExtents) {
    return new btBoxShape(halfExtents);
}

void CollisionShape_CalculateLocalInertia(CollisionShape* self, float mass, Vector3* localInertia) {
    self->calculateLocalInertia(mass, *localInertia);
}
//

// RigidBody
RigidBody* RigidBody_New(float mass, Transform* transform, CollisionShape* shape, Vector3 localInertia) {
    btDefaultMotionState* motionState = new btDefaultMotionState(*transform);
    RigidBody::btRigidBodyConstructionInfo rigidBodyInfo(mass, motionState, shape, localInertia);
    return new RigidBody(rigidBodyInfo);
}

void RigidBody_GetWorldTransform(RigidBody* self, Transform* transform) {
    self->getMotionState()->getWorldTransform(*transform);
}
void RigidBody_SetWorldTransform(RigidBody* self, Transform* transform) {
    self->getMotionState()->setWorldTransform(*transform);
}
//
