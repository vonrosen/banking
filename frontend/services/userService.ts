import { CreateUserRequest } from '@/types/createUserRequest';
import { LoginRequest } from '@/types/loginRequest';
import { User } from '@/types/user';
import { post } from './api';

export class UserService {
  async createUser(request: CreateUserRequest): Promise<User> {
    return post<User>('/v1/users', request);
  }

  async login(request: LoginRequest): Promise<User> {
    return post<User>('/v1/users/login', request);
  }
}
