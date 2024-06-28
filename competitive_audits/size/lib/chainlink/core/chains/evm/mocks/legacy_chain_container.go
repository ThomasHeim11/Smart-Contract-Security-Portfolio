// Code generated by mockery v2.35.4. DO NOT EDIT.

package mocks

import (
	evm "github.com/smartcontractkit/chainlink/v2/core/chains/evm"
	mock "github.com/stretchr/testify/mock"

	types "github.com/smartcontractkit/chainlink/v2/core/chains/evm/types"
)

// LegacyChainContainer is an autogenerated mock type for the LegacyChainContainer type
type LegacyChainContainer struct {
	mock.Mock
}

// ChainNodeConfigs provides a mock function with given fields:
func (_m *LegacyChainContainer) ChainNodeConfigs() types.Configs {
	ret := _m.Called()

	var r0 types.Configs
	if rf, ok := ret.Get(0).(func() types.Configs); ok {
		r0 = rf()
	} else {
		if ret.Get(0) != nil {
			r0 = ret.Get(0).(types.Configs)
		}
	}

	return r0
}

// Get provides a mock function with given fields: id
func (_m *LegacyChainContainer) Get(id string) (evm.Chain, error) {
	ret := _m.Called(id)

	var r0 evm.Chain
	var r1 error
	if rf, ok := ret.Get(0).(func(string) (evm.Chain, error)); ok {
		return rf(id)
	}
	if rf, ok := ret.Get(0).(func(string) evm.Chain); ok {
		r0 = rf(id)
	} else {
		if ret.Get(0) != nil {
			r0 = ret.Get(0).(evm.Chain)
		}
	}

	if rf, ok := ret.Get(1).(func(string) error); ok {
		r1 = rf(id)
	} else {
		r1 = ret.Error(1)
	}

	return r0, r1
}

// Len provides a mock function with given fields:
func (_m *LegacyChainContainer) Len() int {
	ret := _m.Called()

	var r0 int
	if rf, ok := ret.Get(0).(func() int); ok {
		r0 = rf()
	} else {
		r0 = ret.Get(0).(int)
	}

	return r0
}

// List provides a mock function with given fields: ids
func (_m *LegacyChainContainer) List(ids ...string) ([]evm.Chain, error) {
	_va := make([]interface{}, len(ids))
	for _i := range ids {
		_va[_i] = ids[_i]
	}
	var _ca []interface{}
	_ca = append(_ca, _va...)
	ret := _m.Called(_ca...)

	var r0 []evm.Chain
	var r1 error
	if rf, ok := ret.Get(0).(func(...string) ([]evm.Chain, error)); ok {
		return rf(ids...)
	}
	if rf, ok := ret.Get(0).(func(...string) []evm.Chain); ok {
		r0 = rf(ids...)
	} else {
		if ret.Get(0) != nil {
			r0 = ret.Get(0).([]evm.Chain)
		}
	}

	if rf, ok := ret.Get(1).(func(...string) error); ok {
		r1 = rf(ids...)
	} else {
		r1 = ret.Error(1)
	}

	return r0, r1
}

// Slice provides a mock function with given fields:
func (_m *LegacyChainContainer) Slice() []evm.Chain {
	ret := _m.Called()

	var r0 []evm.Chain
	if rf, ok := ret.Get(0).(func() []evm.Chain); ok {
		r0 = rf()
	} else {
		if ret.Get(0) != nil {
			r0 = ret.Get(0).([]evm.Chain)
		}
	}

	return r0
}

// NewLegacyChainContainer creates a new instance of LegacyChainContainer. It also registers a testing interface on the mock and a cleanup function to assert the mocks expectations.
// The first argument is typically a *testing.T value.
func NewLegacyChainContainer(t interface {
	mock.TestingT
	Cleanup(func())
}) *LegacyChainContainer {
	mock := &LegacyChainContainer{}
	mock.Mock.Test(t)

	t.Cleanup(func() { mock.AssertExpectations(t) })

	return mock
}
