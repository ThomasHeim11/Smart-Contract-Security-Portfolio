// Code generated by mockery v2.35.4. DO NOT EDIT.

package mocks

import (
	context "context"

	rpc "github.com/ethereum/go-ethereum/rpc"
	mock "github.com/stretchr/testify/mock"
)

// BatchSender is an autogenerated mock type for the BatchSender type
type BatchSender struct {
	mock.Mock
}

// BatchCallContext provides a mock function with given fields: ctx, b
func (_m *BatchSender) BatchCallContext(ctx context.Context, b []rpc.BatchElem) error {
	ret := _m.Called(ctx, b)

	var r0 error
	if rf, ok := ret.Get(0).(func(context.Context, []rpc.BatchElem) error); ok {
		r0 = rf(ctx, b)
	} else {
		r0 = ret.Error(0)
	}

	return r0
}

// NewBatchSender creates a new instance of BatchSender. It also registers a testing interface on the mock and a cleanup function to assert the mocks expectations.
// The first argument is typically a *testing.T value.
func NewBatchSender(t interface {
	mock.TestingT
	Cleanup(func())
}) *BatchSender {
	mock := &BatchSender{}
	mock.Mock.Test(t)

	t.Cleanup(func() { mock.AssertExpectations(t) })

	return mock
}
